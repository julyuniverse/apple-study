//
//  ScrollContentView3.swift
//  AppleStudy
//
//  Created by mathmaster on 6/2/25.
//

import SwiftUI

struct ScrollContentView3: View {
    @State private var items: [ScrollItem] = []
    @State private var groupedItems: [(date: Date, items: [ScrollItem])] = [] // 년월일로 그룹핑, 최신 순
    
    var body: some View {
        ResizableHeaderScrollView {
            HStack(spacing: 15) {
                Button {
                    
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }
                
                Spacer(minLength: 0)
                
                Button {
                    
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                }
                
                Button {
                    
                } label: {
                    Image(systemName: "bubble")
                        .font(.title3)
                }
            }
            .overlay(content: {
                Text("Apple Store")
                    .fontWeight(.semibold)
            })
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 15)
            .padding(.top, 15)
        } stickyHeader: {
            HStack {
                Text("Total \(25)")
                    .fontWeight(.semibold)
                
                Spacer(minLength: 0)
                
                Button {
                    
                } label: {
                    Image(systemName: "slider.vertical.3")
                        .font(.title3)
                }
            }
            .foregroundStyle(Color.primary)
            .padding(15)
            .padding(.vertical, 10)
        } background: {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .bottom) {
                    Divider()
                }
        } content: {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedItems, id: \.date) { group in
                    Section {
                        ForEach(group.items) { item in
                            Text("id: \(item.id), date: \(item.date, formatter: dateFormatter)")
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                                .padding(.vertical, 2)
                        }
                    } header: {
                        Text("\(group.date, formatter: dateFormatter)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.2))
                    }
                }
            }
        }
        .onAppear {
            var tempItems: [ScrollItem] = []
            let calendar = Calendar.current
            for i in 0..<50 {
                let dayOffset = i / 2
                let baseDate = calendar.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
                let randomSeconds = Double.random(in: 0..<86400)
                let date = calendar.date(byAdding: .second, value: Int(randomSeconds), to: baseDate) ?? baseDate
                tempItems.append(ScrollItem(id: i, date: date, title: "항목 \(i)"))
            }
            items = tempItems
            
            let grouped = Dictionary(grouping: items) { item in
                calendar.startOfDay(for: item.date)
            }
            groupedItems = grouped.map { (date, items) in
                (date: date, items: items.sorted { $0.id < $1.id })
            }
            .sorted { $0.date > $1.date }
        }
    }
    
    // 날짜 포맷터
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}

#Preview {
    ScrollContentView3()
}
