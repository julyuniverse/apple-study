import SwiftUI

struct ScrollViewOffsetsAndContentSize: Equatable {
    var contentOffset: CGPoint
    var contentSize: CGSize
    var bounds: CGRect
}

struct ScrollItem: Identifiable {
    let id: Int
    let date: Date
    let title: String
}

struct ScrollDirectionWithBounceDetectionView: View {
    @State private var scrollDirection: String = "정지" // "위로", "아래로", "정지"
    @State private var lastOffset: CGPoint = .zero
    @State private var lastValidDirection: String = "정지"
    @State private var items: [ScrollItem] = []
    @State private var groupedItems: [(date: Date, items: [ScrollItem])] = [] // 년월일로 그룹핑, 최신 순
    @State private var wasBouncing: Bool = false
    @State private var lastUpdateTime: Date = .distantPast
    private let debounceInterval: TimeInterval = 0.1 // 100ms 디바운스
    private let deltaThreshold: CGFloat = 0.5 // 방향 변경 임계값
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
            }
            .frame(height: 1)
            HStack(spacing: 20) {
                Text("Status Bar")
                Text("Status Bar")
                Text("Status Bar")
                Text("Status Bar")
            }
            .frame(maxWidth: .infinity)
            .frame(height: scrollDirection == "아래로 스크롤" || scrollDirection == "정지" || items.count == 0 ? 100 : 0)
            .background(.blue)
            .clipped()
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(groupedItems, id: \.date) { group in
                        Section(header: Text("\(group.date, formatter: dateFormatter)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.2))) {
                                ForEach(group.items) { item in
                                    Text("id: \(item.id), date: \(item.date, formatter: dateFormatter)")
                                        .frame(height: 50)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(8)
                                        .padding(.vertical, 2)
                                }
                            }
                    }
                }
            }
            .onScrollGeometryChange(for: ScrollViewOffsetsAndContentSize.self, of: { geometry in
                ScrollViewOffsetsAndContentSize(
                    contentOffset: geometry.contentOffset,
                    contentSize: geometry.contentSize,
                    bounds: geometry.bounds
                )
            }) { oldValue, newValue in
                let currentOffset = newValue.contentOffset
                let delta = currentOffset.y - lastOffset.y
                let currentTime = Date()
                
                // 바운스 영역 감지
                let contentHeight = newValue.contentSize.height
                let viewHeight = newValue.bounds.height
                let maxOffsetY = max(0, contentHeight - viewHeight)
                let isBouncingAtTop = currentOffset.y < 0
                let isBouncingAtBottom = currentOffset.y > maxOffsetY
                let isBouncing = isBouncingAtTop || isBouncingAtBottom
                
                // 디버깅 로그
                print("Offset: \(currentOffset.y), Delta: \(delta), isBouncingAtTop: \(isBouncingAtTop), isBouncingAtBottom: \(isBouncingAtBottom), LastValidDirection: \(lastValidDirection), wasBouncing: \(wasBouncing)")
                
                if isBouncing {
                    wasBouncing = true
                } else {
                    // 정상 스크롤 영역
                    if wasBouncing {
                        // 바운스에서 정상 영역으로 전환 시 작은 delta 무시
                        if scrollDirection != lastValidDirection {
                            scrollDirection = lastValidDirection
                            logScrollDirection(lastValidDirection)
                        }
                    } else {
                        // 유효한 스크롤 동작, 디바운스 적용
                        let newDirection = if delta > deltaThreshold {
                            "위로 스크롤"
                        } else if delta < -deltaThreshold {
                            "아래로 스크롤"
                        } else {
                            lastValidDirection // 기존 방향 유지
                        }
                        
                        if newDirection != lastValidDirection && currentTime.timeIntervalSince(lastUpdateTime) > debounceInterval {
                            lastValidDirection = newDirection
                            scrollDirection = newDirection
                            lastUpdateTime = currentTime
                            logScrollDirection(newDirection)
                        }
                    }
                    wasBouncing = false
                }
                
                lastOffset = currentOffset
            }
            .overlay(
                VStack {
                    Text("scrollDirection: \(scrollDirection)")
                        .font(.headline)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                    Text("lastValidDirection: \(lastValidDirection)")
                        .font(.headline)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                    Text("bouncing: \(wasBouncing)")
                        .font(.headline)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                }
                    .padding(.top, 50)
                , alignment: .top
            )
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
        .animation(.easeInOut(duration: 0.2), value: scrollDirection == "아래로 스크롤" || scrollDirection == "정지" ? 1 : 0)
    }
    
    // 스크롤 방향 로깅
    private func logScrollDirection(_ direction: String) {
        print("Scroll direction logged: \(direction) at \(Date())")
    }
    
    // 날짜 포맷터
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}

#Preview {
    ScrollDirectionWithBounceDetectionView()
}
