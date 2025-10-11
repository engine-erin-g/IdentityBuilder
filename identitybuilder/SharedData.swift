//
//  SharedData.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import Foundation

class SharedData {
    static let shared = SharedData()
    private let userDefaults = UserDefaults(suiteName: "group.com.yourcompany.identitybuilder")
    
    private init() {}
    
    // Keys for shared data
    private enum Keys {
        static let widgetData = "widgetData"
        static let lastUpdate = "lastUpdate"
    }
    
    func saveWidgetData(_ data: WidgetData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        userDefaults?.set(encoded, forKey: Keys.widgetData)
        userDefaults?.set(Date(), forKey: Keys.lastUpdate)
    }
    
    func loadWidgetData() -> WidgetData? {
        guard let data = userDefaults?.data(forKey: Keys.widgetData),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    func getLastUpdateDate() -> Date? {
        return userDefaults?.object(forKey: Keys.lastUpdate) as? Date
    }
}

// Make WidgetData encodable for sharing
extension WidgetData: Codable {}
extension WidgetHabit: Codable {}