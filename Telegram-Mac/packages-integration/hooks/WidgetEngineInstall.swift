import Foundation
import WidgetEngineXPC

func installWidgetEngineService() {
    let serviceName = WidgetEngineXPC.embeddedServiceName() ?? "xyz.nextalone.nagram.WidgetEngine"
    WidgetEngineXPC.install(serviceName: serviceName)
}
