//
//  SettingsView.swift
//  SwiftUITest
//
//  Created by Thomas Visser on 18/01/2020.
//  Copyright © 2020 Thomas Visser. All rights reserved.
//

import Foundation
import SwiftUI
import Parma

struct SettingsContainerView: View {

    @SwiftUI.Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        NavigationView {
            SettingsView(presentationMode: presentationMode)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct SettingsView: View {
    @EnvironmentObject var env: Environment
    @Binding var presentationMode: PresentationMode
    @State var destination: Destination?

    var body: some View {
        List {
            Section {
                navigationLink(destination: .safariView("https://www.construct5e.app/help/")) {
                    Text("Help center")
                }

                Button(action: {
                    if self.env.canSendMail {
                        self.env.sendMail()
                    }
                }) {
                    VStack(alignment: .leading) {
                        Text("Send feedback")
                        if !self.env.canSendMail {
                            Text("Your device is not configured to send mail").font(.footnote).foregroundColor(Color(UIColor.secondaryLabel))
                        }
                    }
                }.disabled(!self.env.canSendMail)

                Button(action: {
                    env.rateInAppStore()
                }) {
                    Text("Please rate Construct")
                }
            }

            #if DEBUG
            Section(header: Text("Debug options")) {
                Button(action: {
                    try? self.env.database.keyValueStore.put(Preferences())
                }) {
                    Text("Reset all preferences")
                }

                Button(action: {
                    try? self.env.database.queue.write { db in
                        try Compendium(self.env.database).importDefaultContent(db)
                    }
                }) {
                    Text("Import default content")
                }
            }
            #endif

            Section {
                navigationLink(destination: .ogl) {
                    Text("Open Game License")
                }

                navigationLink(destination: .acknowledgements) {
                    Text("Third-party software")
                }

                navigationLink(destination: .safariView("https://www.construct5e.app/privacy_policy/")) {
                    Text("Privacy policy").foregroundColor(Color.primary)
                }

                navigationLink(destination: .safariView("https://www.construct5e.app/terms_conditions/")) {
                    Text("Terms & conditions")
                }

                Text("Version \(version)")
            }
        }
        .listStyle(GroupedListStyle())
        .sheet(item: sheetDest, content: sheetView)
        .navigationBarTitle("About", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            self.presentationMode.dismiss()
        }) {
            Text("Done").bold()
        })
    }

    var version: String {
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
                return "unknown"
        }

        return "\(version) (\(build))"
    }

    @ViewBuilder
    func navigationLink<Label>(destination: Destination, @ViewBuilder label: () -> Label) -> some View where Label: View {
        if let view = dest(destination: destination) {
            NavigationLink(
                destination: view,
                isActive: Binding(
                    get: { self.destination == destination },
                    set: {
                        if $0 {
                            self.destination = destination
                        } else if self.destination == destination {
                            self.destination = nil
                        }
                    }
                ),
                label: label
            )
        } else {
            NavigationRowButton(action: {
                self.destination = destination
            }, label: {
                label().foregroundColor(Color.primary)
            })
        }
    }

    func dest(destination: Destination) -> AnyView? {
        switch destination {
        case nil: return nil
        case .safariView: return nil
        case .ogl:
            return ScrollView {
                try? Parma(fromResource: "ogl", ofType: "md")
            }.eraseToAnyView
        case .acknowledgements:
            return ScrollView {
                try? Parma(fromResource: "software_licenses", ofType: "md")
            }.eraseToAnyView
        }
    }

    var sheetDest: Binding<Destination?> {
        Binding(get: {
            if case .safariView(let url) = self.destination {
                return .safariView(url)
            }
            return nil
        }, set: {
            self.destination = $0
        })
    }

    func sheetView(destination: Destination?) -> AnyView {
        switch destination {
        case .safariView(let url):
            return SafariView(url: URL(string: url)!).edgesIgnoringSafeArea(.all).eraseToAnyView
        default:
            return EmptyView().eraseToAnyView
        }
    }

    enum Destination: Hashable, Identifiable {
        var id: Int { hashValue }

        case safariView(String)
        case ogl
        case acknowledgements
    }
}

extension Parma {
    init?(fromResource resource: String, ofType type: String, in bundle: Bundle = .main) throws {
        guard let path = bundle.path(forResource: resource, ofType: type) else {
            throw Error.fileNotFound
        }

        self.init(try String(contentsOfFile: path))
    }

    enum Error: Swift.Error {
        case fileNotFound
    }
}
