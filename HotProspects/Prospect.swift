//
//  Prospect.swift
//  HotProspects
//
//  Created by Yes on 14.12.2019.
//  Copyright © 2019 Yes. All rights reserved.
//

import Foundation

class Prospect: Identifiable, Codable, Comparable {
    let id = UUID()
    var name = "Anonymous"
    var emailAddress = ""
    fileprivate(set) var isContacted = false
    
    static func == (lhs: Prospect, rhs: Prospect) -> Bool {
        lhs.name == rhs.name
    }
    
    public static func < (lhs: Prospect, rhs: Prospect) -> Bool {
       lhs.name < rhs.name
    }
}

class Prospects: ObservableObject {
    static let saveKey = "SavedData"
    @Published private(set) var people: [Prospect]
    
    static private var fileName: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(Self.saveKey)
    }
    
    func toggle(_ prospect: Prospect) {
        objectWillChange.send()
        prospect.isContacted.toggle()
        save()
    }
    
    private func save() {
        // using UserDefaults
//        if let encoded = try? JSONEncoder().encode(people) {
//            UserDefaults.standard.set(encoded, forKey: Self.saveKey)
//        }

        // using JSON and documents directory
        do {
            let data = try JSONEncoder().encode(people)
            try data.write(to: Prospects.fileName, options: [.atomicWrite, .completeFileProtection])
        } catch {
            print("Unable to save data.")
        }
    }
    
    func add(_ prospect: Prospect) {
        people.append(prospect)
        save()
    }
            
    init() {
        // using UserDefaults
//        if let data = UserDefaults.standard.data(forKey: Self.saveKey) {
//            if let decoded = try? JSONDecoder().decode([Prospect].self, from: data) {
//                self.people = decoded
//                return
//            }
//        }

        // using JSON and documents directory
        do {
            let data = try Data(contentsOf: Prospects.fileName)
            if let decoded = try? JSONDecoder().decode([Prospect].self, from: data) {
                self.people = decoded
                return
            }
        } catch {
            print("Unable to load saved data.")
        }
        
        self.people = []
    }
}
