//
//  SharedData.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import Foundation

class SharedData {
    static let shared = SharedData()
    // Try to use app group, fall back to standard UserDefaults if not available
    private let userDefaults: UserDefaults? = {
        // First try app group (for widgets) - matches entitlements file
        if let appGroupDefaults = UserDefaults(suiteName: "group.erin-ndrio.identitybuilder") {
            return appGroupDefaults
        }
        // Fall back to standard UserDefaults (works without app group capability)
        return UserDefaults.standard
    }()

    private init() {}
    
    // Keys for shared data
    private enum Keys {
        static let widgetData = "widgetData"
        static let lastUpdate = "lastUpdate"
    }
    
    func saveWidgetData(_ data: WidgetData) async {
        do {
            let encoded = try JSONEncoder().encode(data)
            userDefaults?.set(encoded, forKey: Keys.widgetData)
            userDefaults?.set(Date(), forKey: Keys.lastUpdate)
        } catch {
            print("Error encoding widget data: \(error)")
        }
    }

    func loadWidgetData() -> WidgetData? {
        guard let data = userDefaults?.data(forKey: Keys.widgetData) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(WidgetData.self, from: data)
        } catch {
            print("Error decoding widget data: \(error)")
            return nil
        }
    }
    
    func getLastUpdateDate() -> Date? {
        return userDefaults?.object(forKey: Keys.lastUpdate) as? Date
    }
}