//
//  ScrollContentView.swift
//  AppleStudy
//
//  Created by mathmaster on 5/12/25.
//

import SwiftUI

struct ScrollContentView: View {
    @State var phase: ScrollPhase?
    @State private var isNewlyVisibleItemId: SomeItem.ID? // 스크롤 영역에서 "보이기 시작한" 아이템의 ID
    @State var firstItem: SomeItem?
    
    var body: some View {
        VStack {
            if let phase {
                Text("phase: \(phase)")
            }
            ScrollView {
                LazyVStack {
                    ForEach(SomeItem.previewItem) { item in
                        SomeItemView(item)
                            .background {
                                if isNewlyVisibleItemId == item.id {
                                    Rectangle().stroke(lineWidth: 3.0).foregroundColor(.red)
                                }
                            }
                            .onScrollVisibilityChange(threshold: 0.1) { isVisible in
                                print("[\(item.id)] isVisible: \(isVisible)  ")
                                if isVisible {
                                    isNewlyVisibleItemId = item.id
                                    if let lastItem = SomeItem.previewItem.last, lastItem.id == item.id {
                                        print("last")
                                        print("more activities...")
                                    }
                                }
                            }
                    }
                }
            }
        }
        .onScrollPhaseChange { oldPhase, newPhase, context in
            print("old: \(oldPhase) -> new: \(newPhase)")
            phase = newPhase
        }
    }
}

struct SomeItem: Identifiable {
    let id: Int
    let text: String = "Item"
    
    static let previewItem = {
        var items = [SomeItem]()
        for i in 0..<100 {
            items.append(SomeItem(id: i))
        }
        return items
    }()
}

struct SomeItemView: View {
    let item: SomeItem
    
    init(_ item: SomeItem) {
        self.item = item
    }
    
    var body: some View {
        Text("\(item.text) \(item.id)")
    }
}

#Preview {
    ScrollContentView()
}
