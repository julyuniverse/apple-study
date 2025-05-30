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
    @State private var scrollId: SomeItem.ID?
    @State var selectedDate = Date()
    @State var firstItemDate = Date()
    var items: [SomeItem] = SomeItem.previewItem
    @State private var showDatePicker = false
    @State private var isBeyondZero: Bool = false // 이 State 변숫값이 변경되면 뷰의 body 계산이 이루어짐
    @State private var showStatusBar = true
    @State private var lastOffset: CGFloat = 0.0
    @State var contentSizeHeight: CGFloat = 0.0
    @State var containerSizeHeight: CGFloat = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
            if let phase {
                Text("phase: \(phase)")
            }
            Text("scroll is beyond zero: \(isBeyondZero)")
            Button("날짜 선택") {
                showDatePicker = true
            }
            HStack(spacing: 20) {
                Text("Status Bar")
                Text("Status Bar")
                Text("Status Bar")
                Text("Status Bar")
            }
            .frame(maxWidth: .infinity)
            .frame(height: showStatusBar || items.count == 0 ? 100 : 0)
            .background(.blue)
            .clipped()
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
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrollId, anchor: .top)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentSize.height
            } action: { oldValue, newValue in
                contentSizeHeight = newValue
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.containerSize.height
            } action: { oldValue, newValue in
                containerSizeHeight = newValue
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { oldValue, newValue in
                // 임계값을 설정하여 미세한 변화 무시 (예: 1.0)
                let threshold: CGFloat = 1.0

                // 미세 변화는 무시
                if abs(newValue - oldValue) < threshold {
                    return
                }
                if newValue >= 0 && newValue <= abs(contentSizeHeight - containerSizeHeight) && phase == .interacting {
                    if (newValue - lastOffset <= 0.0) {
                        showStatusBar = true
                    } else {
                        showStatusBar = false
                    }
                    lastOffset = newValue
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showStatusBar)
        .sheet(isPresented: $showDatePicker) {
            VStack {
                DatePicker("날짜 선택", selection: Binding(
                    get: { selectedDate },
                    set: { newDate in
                        selectedDate = newDate
                        firstItemDate = newDate
                        print("selected: \(String(describing: selectedDate))")
                        
                        // 선택한 날짜와 일치하는 아이템 찾기
                        if let targetItem = items.first(where: {
                            Calendar.current.isDate($0.date, inSameDayAs: newDate)
                        }) {
                            scrollId = targetItem.id
                        } else {
                            print("해당 날짜에 맞는 아이템이 없습니다.")
                        }
                        showDatePicker = false // 날짜 선택 후 자동으로 닫힘
                    }
                ), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
            }
            .presentationDetents([.medium]) // 팝업 높이 조절
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
        let startDate = Date() // 또는 특정 기준 날짜(DateComponents로 생성)
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
