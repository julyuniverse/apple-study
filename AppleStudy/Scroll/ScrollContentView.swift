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
    @State var seletedDate: Date?
    
    var body: some View {
        VStack {
            if let phase {
                Text("phase: \(phase)")
            }
            DatePicker("날짜 선택", selection: Binding(
                get: { seletedDate ?? Date() },
                set: { newDate in
                    seletedDate = newDate
                    print("selected")
                }
            ), displayedComponents: .date)
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
    let date: Date
    
    // 예: 오늘부터 과거로 100일치
    static let previewItem: [SomeItem] = {
        let calendar = Calendar.current
        let startDate = Date()  // 또는 특정 기준 날짜(DateComponents로 생성)
        return (0..<100)
            .map { offset in
                let d = calendar.date(byAdding: .day, value: -offset, to: startDate)!
                return SomeItem(id: offset, date: d)
            }
            // 최신일자부터 과거일자 순으로 정렬(여기선 이미 offset=0이 최신)
    }()
}

struct SomeItemView: View {
    let item: SomeItem
    
    init(_ item: SomeItem) {
        self.item = item
    }
    
    var body: some View {
        Text("\(item.date) \(item.id)")
    }
}

#Preview {
    ScrollContentView()
}
