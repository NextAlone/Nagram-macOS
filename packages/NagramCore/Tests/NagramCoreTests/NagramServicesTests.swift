import XCTest
import SwiftSignalKit
@testable import NagramCore

private final class DeepLXStubProtocol: URLProtocol {
    static var bodies: [[String: Any]] = []
    static var reply: (([String: Any]) -> [String: Any])?

    override class func canInit(with request: URLRequest) -> Bool {
        return request.url?.host == "127.0.0.1" && request.url?.port == 1188
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        var data = request.httpBody
        if data == nil, let stream = request.httpBodyStream {
            stream.open()
            var buffer = [UInt8](repeating: 0, count: 65536)
            var collected = Data()
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count <= 0 {
                    break
                }
                collected.append(buffer, count: count)
            }
            stream.close()
            data = collected
        }
        let body = (data.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any]) ?? [:]
        DeepLXStubProtocol.bodies.append(body)
        let answer = DeepLXStubProtocol.reply?(body) ?? [:]
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: try! JSONSerialization.data(withJSONObject: answer))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
    }
}

final class NagramServicesTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DeepLXStubProtocol.bodies = []
        DeepLXStubProtocol.reply = nil
        URLProtocol.registerClass(DeepLXStubProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(DeepLXStubProtocol.self)
        super.tearDown()
    }

    private func deepLX() -> NagramService {
        return NagramServicePreset.all.first(where: { $0.id == "deeplx" })!.make()
    }

    func testDeepLXPresetNeedsNoKey() {
        XCTAssertFalse(deepLX().useKey)
        XCTAssertTrue(NagramServicePreset.all.first(where: { $0.id == "deepl" })!.make().useKey)
    }

    private func run(_ signal: Signal<[String], NagramServiceError>) -> Result<[String], NagramServiceError> {
        let done = expectation(description: "translate")
        var result: Result<[String], NagramServiceError>?
        let disposable = signal.start(next: { value in
            result = .success(value)
        }, error: { error in
            result = .failure(error)
            done.fulfill()
        }, completed: {
            done.fulfill()
        })
        wait(for: [done], timeout: 10)
        disposable.dispose()
        return result!
    }

    func testDeepLXPresetIsATranslationService() {
        let service = deepLX()
        XCTAssertEqual(service.protocol, "deeplx")
        XCTAssertFalse(service.isLlm)
        XCTAssertTrue(NagramService.translationProtocols.contains("deeplx"))
        XCTAssertNil(service.validationError)
        XCTAssertEqual(service.endpointUrl?.absoluteString, "http://127.0.0.1:1188/translate")
    }

    func testDeepLXSendsOneTextPerRequestInOrder() {
        DeepLXStubProtocol.reply = { body in
            return ["code": 200, "data": "<" + (body["text"] as? String ?? "") + ">"]
        }
        var service = deepLX()
        service.model = "less"
        let result = run(NagramServiceClient.translate(["one", "two", "three"], to: "de", service: service))
        XCTAssertEqual(try? result.get(), ["<one>", "<two>", "<three>"])
        XCTAssertEqual(DeepLXStubProtocol.bodies.map { $0["text"] as? String }, ["one", "two", "three"])
        XCTAssertEqual(DeepLXStubProtocol.bodies.map { $0["target_lang"] as? String }, ["DE", "DE", "DE"])
        XCTAssertEqual(DeepLXStubProtocol.bodies.first?["formality"] as? String, "less")
    }

    func testDeepLXFailsOnAnErrorCode() {
        DeepLXStubProtocol.reply = { _ in
            return ["code": 429, "message": "Too Many Requests"]
        }
        let result = run(NagramServiceClient.translate(["one"], to: "de", service: deepLX()))
        guard case .failure(.badResponse) = result else {
            return XCTFail("expected badResponse, got \(result)")
        }
    }
}
