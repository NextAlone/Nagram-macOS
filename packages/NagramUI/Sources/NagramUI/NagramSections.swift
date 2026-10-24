import Cocoa
import NagramCore

public func nagramSections() -> [NagramSection] {
    return [
        NagramSection(id: "interface", title: nagramString("lng_nagram_interface"), rows: nagramInterfaceRows),
        NagramSection(id: "chats", title: nagramString("lng_nagram_chats"), rows: nagramChatsRows),
        NagramSection(id: "messages", title: nagramString("lng_nagram_messages"), rows: nagramMessagesRows),
        NagramSection(id: "compose", title: nagramString("lng_nagram_compose"), rows: nagramComposeRows),
        NagramSection(id: "menu", title: nagramString("lng_nagram_menu"), rows: nagramMenuRows),
        NagramSection(id: "media", title: nagramString("lng_nagram_media"), rows: nagramMediaRows),
        NagramSection(id: "privacy", title: nagramString("lng_nagram_privacy"), rows: nagramPrivacyRows),
        NagramSection(id: "services", title: nagramString("lng_nagram_services"), rows: nagramServicesRows),
        NagramSection(id: "rules", title: nagramString("lng_nagram_rules"), rows: nagramRulesRows),
        NagramSection(id: "network", title: nagramString("lng_nagram_network"), rows: nagramNetworkRows),
        NagramSection(id: "config", title: nagramString("lng_nagram_config_title"), rows: nagramConfigRows),
    ]
}
