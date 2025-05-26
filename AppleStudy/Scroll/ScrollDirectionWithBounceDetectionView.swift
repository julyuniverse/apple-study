import SwiftUI

struct ScrollViewOffsetsAndContentSize: Equatable {
    var contentOffsetY: CGFloat
    var contentSize: CGSize
    var bounds: CGRect
}

struct ContentHeightPreferenceKey: PreferenceKey, Sendable {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ScrollDirectionWithBounceDetectionView: View {
    @State private var previousScrollOffset: CGFloat = 0.0
    @State private var scrollDirection: String = "정지" // "위로", "아래로", "정지"
    @State private var lastValidScrollDirection: String = "정지" // 바운스 영역 진입 전 마지막 유효 스크롤 방향

    @State private var scrollViewHeight: CGFloat = 0.0

    var body: some View {
        ScrollView {
            VStack {
                ForEach(0..<100) { index in
                    Text("항목 \(index)")
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.vertical, 2)
                }
            }
            .padding()
            .background(
                GeometryReader { contentGeometry in
                    Color.clear
                        .preference(key: ContentHeightPreferenceKey.self, value: contentGeometry.size.height)
                }
            )
        }
        .background(
            GeometryReader { scrollViewGeometry in
                Color.clear
                    .onAppear {
                        scrollViewHeight = scrollViewGeometry.size.height
                        print("[초기화] ScrollView 높이: \(String(format: "%.2f", scrollViewHeight))")
                    }
                    .onChange(of: scrollViewGeometry.size) { oldSize, newSize in
                        scrollViewHeight = newSize.height
                        print("[변경] ScrollView 높이: \(String(format: "%.2f", oldSize.height)) -> \(String(format: "%.2f", newSize.height))")
                    }
            }
        )
        .onScrollGeometryChange(for: ScrollViewOffsetsAndContentSize.self, of: { geometry in
            ScrollViewOffsetsAndContentSize(
                contentOffsetY: geometry.contentOffset.y,
                contentSize: geometry.contentSize,
                bounds: geometry.bounds
            )
        }) { oldValue, newValue in
            let currentOffset = newValue.contentOffsetY
            let contentHeight = newValue.contentSize.height
            let viewHeight = newValue.bounds.height
            let maxOffsetY = max(0, contentHeight - viewHeight)

            let minScrollOffset: CGFloat = 0
            let maxScrollOffset: CGFloat = max(0, contentHeight - scrollViewHeight)

            let epsilon: CGFloat = 0.5

            // 로그를 먼저 출력하여 현재 값을 확인
            print("--- 스크롤 이벤트 (직전 방향: \(previousScrollOffset <= currentOffset ? "아래로" : "위로"), 현재 감지될 방향: \(scrollDirection)) ---")
            print("  현재 Offset: \(String(format: "%.2f", currentOffset))")
            print("  이전 Offset: \(String(format: "%.2f", previousScrollOffset))")
            print("  콘텐츠 높이: \(String(format: "%.2f", contentHeight))")
            print("  ScrollView 높이: \(String(format: "%.2f", scrollViewHeight))")
            print("  최소 스크롤 가능 Offset: \(String(format: "%.2f", minScrollOffset))")
            print("  최대 스크롤 가능 Offset: \(String(format: "%.2f", maxScrollOffset))")
            print("  Last Valid Direction: \(lastValidScrollDirection)")


            // MARK: - 바운스 영역 판단 및 방향 고정
            if contentHeight <= scrollViewHeight {
                // 1. 콘텐츠가 스크롤뷰보다 작거나 같아서 스크롤이 불가능한 경우
                if scrollDirection != "정지" {
                    scrollDirection = "정지"
                    print("  -> 콘텐츠가 스크롤뷰보다 작아 '\(scrollDirection)' 상태 유지.")
                }
            }
            else if currentOffset < minScrollOffset - epsilon {
                // 2. 상단 바운스 영역에 진입했을 때
                if scrollDirection != lastValidScrollDirection {
                    scrollDirection = lastValidScrollDirection // 이전 유효 방향으로 고정
                    print("  -> 상단 바운스 영역 진입. 방향 고정: '\(lastValidScrollDirection)'")
                }
            }
            else if currentOffset > maxScrollOffset + epsilon {
                // 3. 하단 바운스 영역에 진입했을 때
                if scrollDirection != lastValidScrollDirection {
                    scrollDirection = lastValidScrollDirection // 이전 유효 방향으로 고정
                    print("  -> 하단 바운스 영역 진입. 방향 고정: '\(lastValidScrollDirection)'")
                }
            }
            // MARK: - 정상 스크롤 영역에서만 방향 감지
            else {
                // 스크롤이 움직였을 때 (정상 스크롤 영역)
                if abs(currentOffset - previousScrollOffset) > epsilon { // 미세한 움직임 제외
                    if currentOffset > previousScrollOffset {
                        if scrollDirection != "아래로" {
                            scrollDirection = "아래로"
                            lastValidScrollDirection = "아래로" // 유효 방향 업데이트
                            print("  -> '\(scrollDirection)' 스크롤 중.")
                        }
                    } else if currentOffset < previousScrollOffset {
                        if scrollDirection != "위로" {
                            scrollDirection = "위로"
                            lastValidScrollDirection = "위로" // 유효 방향 업데이트
                            print("  -> '\(scrollDirection)' 스크롤 중.")
                        }
                    }
                } else {
                    // 스크롤이 멈췄을 때 (미세한 움직임도 없는 경우)
                    if scrollDirection != "정지" {
                        scrollDirection = "정지"
                        print("  -> 스크롤 '\(scrollDirection)'.")
                    }
                }
            }
            previousScrollOffset = currentOffset
        }
        .overlay(
            VStack {
                Text("스크롤 방향: \(scrollDirection)")
                    .font(.headline)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                Spacer()
            }
            .padding(.top, 50)
            , alignment: .top
        )
    }
}

#Preview {
    ScrollDirectionWithBounceDetectionView()
}
