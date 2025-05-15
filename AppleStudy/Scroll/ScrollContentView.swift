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
    @State var selectedDate = Date()
    @State var firstItemDate = Date()
    var items: [SomeItem] = SomeItem.previewItem
    
    var body: some View {
        VStack {
            if let phase {
                Text("phase: \(phase)")
            }
            DatePicker("날짜 선택", selection: Binding(
                get: { selectedDate },
                set: { newDate in
                    selectedDate = newDate
                    firstItemDate = newDate
                    print("selected: \(String(describing: selectedDate))")
                }
            ), displayedComponents: .date)
            ScrollView {
                LazyVStack {
                    ForEach(items) { item in
                        SomeItemView(item)
                            .background {
                                if isNewlyVisibleItemId == item.id {
                                    Rectangle().stroke(lineWidth: 3.0).foregroundColor(.red)
                                }
                            }
                            .onScrollVisibilityChange(threshold: 0.1) { isVisible in
                                //                                print("[\(item.id)] isVisible: \(isVisible)")
                                if isVisible {
                                    isNewlyVisibleItemId = item.id
                                    if let lastItem = SomeItem.previewItem.last, lastItem.id == item.id {
                                        print("last")
                                        print("more activities...")
                                    }
                                    if let firstItem = items.first, !Calendar.current.isDate(firstItem.date, inSameDayAs: firstItemDate), Calendar.current.isDate(item.date, inSameDayAs: firstItemDate) {
                                        print("first")
                                        print("more activities...")
                                        // 데이터를 가져온 후 firstItemDate 날짜를 가져온 데이터에서 가장 큰 날짜로 설정하는 로직 필요함.
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
            .map { offset in // 최신일자부터 과거일자 순으로 정렬(여기선 이미 offset=0이 최신)
                let d = calendar.date(byAdding: .day, value: -offset, to: startDate)!
                return SomeItem(id: offset, date: d)
            }
    }()
}

struct SomeItemView: View {
    let item: SomeItem
    
    init(_ item: SomeItem) {
        self.item = item
    }
    
    var body: some View {
        Text("\(item.id) \(formattedDate(item.date))")
    }
}

func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

#Preview {
    ScrollContentView()
}
