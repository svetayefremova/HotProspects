//
//  ProspectsView.swift
//  HotProspects
//
//  Created by Yes on 14.12.2019.
//  Copyright © 2019 Yes. All rights reserved.
//

import SwiftUI
import CodeScanner
import UserNotifications

enum FilterType {
    case none, contacted, uncontacted
}

enum SortedType {
    case none, recent, name
}

struct ProspectsView: View {
    let filter: FilterType
    @EnvironmentObject var prospects: Prospects
    var filteredProspects: [Prospect] {
        switch filter {
        case .none:
            return prospects.people
        case .contacted:
            return prospects.people.filter { $0.isContacted }
        case .uncontacted:
            return prospects.people.filter { !$0.isContacted }
        }
    }
    var sortedProspects: [Prospect] {
        switch sortedBy {
        case .none:
            return filteredProspects
        case .recent:
            return filteredProspects.sorted(by: { $0.createdAt > $1.createdAt })
        case .name:
            return filteredProspects.sorted(by: { $0.name < $1.name })
        }
    }
    @State private var sortedBy: SortedType = .none
    
    @State private var isShowingScanner = false
    @State private var showingSortedSheet = false
    @State private var isSorted = false
    
    var title: String {
        switch filter {
        case .none:
            return "Everyone"
        case .contacted:
            return "Contacted people"
        case .uncontacted:
            return "Uncontacted people"
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(isSorted ? sortedProspects : filteredProspects) { prospect in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(prospect.name)
                                .font(.headline)
                            Text(prospect.emailAddress)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if self.filter == .none && prospect.isContacted {
                            Image(systemName: "checkmark.seal.fill")
                                .frame(width: 32, height: 32)
                                .foregroundColor(.green)
                        }
                    }.contextMenu {
                        if !prospect.isContacted {
                            Button("Remind Me") {
                                self.addNotification(for: prospect)
                            }
                        }
                        Button(prospect.isContacted ? "Mark Uncontacted" : "Mark Contacted" ) {
                            self.prospects.toggle(prospect)
                        }
                    }
                }
            }
            .navigationBarTitle(title)
            .navigationBarItems(leading: Button("Sort") {
                self.showingSortedSheet = true
            }, trailing: Button(action: {
                self.isShowingScanner = true
            }) {
                Image(systemName: "qrcode.viewfinder")
                Text("Scan")
            })
        }
        .sheet(isPresented: $isShowingScanner) {
            CodeScannerView(codeTypes: [.qr], simulatedData: "Paul Hudson\npaul@hackingwithswift.com", completion: self.handleScan)
        }
        .actionSheet(isPresented: $showingSortedSheet) {
            ActionSheet(title: Text("Select a sorted filter"), buttons: [
                .default(Text("By name")) {
                    self.sortedBy = SortedType.name
                    self.isSorted = true
                },
                .default(Text("By most recent")) {
                    self.sortedBy = SortedType.recent
                    self.isSorted = true
                },
                .destructive(Text("Remove sorting")) {
                    self.sortedBy = SortedType.none
                    self.isSorted = false
                },
                .cancel()
            ])
        }
    }

    
    func addNotification(for prospect: Prospect) {
        let center = UNUserNotificationCenter.current()

        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = UNNotificationSound.default

            var dateComponents = DateComponents()
            dateComponents.hour = 9
//            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            // FOR TEST
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }

        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        addRequest()
                    } else {
                        print("D'oh")
                    }
                }
            }
        }
    }
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
       self.isShowingScanner = false
       switch result {
       case .success(let code):
           let details = code.components(separatedBy: "\n")
           guard details.count == 2 else { return }

           let person = Prospect()
           person.name = details[0]
           person.emailAddress = details[1]
           
           let currentDateTime = Date()

           // initialize the date formatter and set the style
           let formatter = DateFormatter()
           formatter.timeStyle = .medium
           formatter.dateStyle = .long

           // get the date time String from the date object
           person.createdAt = formatter.string(from: currentDateTime)
           
           self.prospects.add(person)
       case .failure(let error):
           print("Scanning failed", error)
       }
    }
}

struct ProspectsView_Previews: PreviewProvider {
    static var previews: some View {
        ProspectsView(filter: .none)
    }
}
