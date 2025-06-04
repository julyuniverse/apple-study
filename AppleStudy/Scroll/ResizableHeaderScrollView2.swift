//
//  ResizableHeaderScrollView2.swift
//  AppleStudy
//
//  Created by July universe on 6/4/25.
//

import SwiftUI

struct ResizableHeaderScrollView2<FixedTopHeader: View, Header: View, Background: View, Content: View>: View {
    @ViewBuilder var fixedTopHeader: FixedTopHeader
    @ViewBuilder var header: Header
    /// Only for header background not for the entire view
    @ViewBuilder var background: Background
    @ViewBuilder var content: Content
    /// View Properties
    @State private var currentDragOffset: CGFloat = 0
    @State private var previousDragOffset: CGFloat = 0
    @State private var headerOffset: CGFloat = 0
    @State private var fixedTopHeaderSize: CGFloat = 0
    @State private var headerSize: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .top) {
            CombinedHeaderView()
            
            VStack(spacing: 0) {
                
                Color.clear
                    .frame(height: fixedTopHeaderSize + (headerSize - headerOffset))
                
                ScrollView(.vertical) {
                    content
                }
                .frame(maxWidth: .infinity)
                // As you can see, when the scroll offset is less than the header height, and our condition on gesture end was never met, leaving a gap like this. To solve this, add a condition to the gesture end that if the scroll offset is less than the header height, reset the header offset to zero.
                // (보시다시피, 스크롤 오프셋이 헤더 높이보다 작을 때 제스처 끝의 조건이 충족되지 않아 이와 같은 틈이 발생합니다. 이 문제를 해결하려면 제스처 끝에 스크롤 오프셋이 헤더 높이보다 작으면 헤더 오프셋을 0으로 재설정하는 조건을 추가합니다.)
                .onScrollGeometryChange(for: CGFloat.self, of: {
                    $0.contentOffset.y + $0.contentInsets.top
                }, action: { oldValue, newValue in
                    scrollOffset = newValue
                    print("scrollOffset: \(scrollOffset)")
                    
                    // Add a small animation to headerOffset change when scrollOffset is involved
                    // This helps to smooth out the transition when scrolling dictates the header position
                    if newValue < headerSize && headerOffset > 0 && currentDragOffset == 0 {
                        // Only snap to 0 if we're scrolling up past the header and not currently dragging
                        if newValue <= 0 {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                headerOffset = 0
                            }
                        }
                    }
                })
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged({ value in
                            /// Adjusting the minimun distanse value
                            /// Thus it starts from 0.
                            // The reason behind using the value "50" is that it initiates the resizing process after a certain period, allowing for scrolling. However, if you desire an instantaneous resizing effect, you can replace this value with "10," which is the same as the "minimumDistance" value.
                            // ("50" 값을 사용하는 이유는 일정 시간 후에 크기 조절 프로세스를 시작하여 스크롤을 가능하게 하기 때문입니다. 하지만 즉각적인 크기 조절 효과를 원하면 이 값을 "minimumDistance" 값과 동일한 "10"으로 바꿀 수 있습니다.)
                            
                            // It's often better to avoid `rounded()` directly on the drag offset for smoother animation.
                            // Let the system handle the precise rendering.
                            let dragOffset = -max(0, abs(value.translation.height) - 10) * (value.translation.height < 0 ? -1 : 1)
                            
                            previousDragOffset = currentDragOffset
                            currentDragOffset = dragOffset
                            
                            let deltaOffset = currentDragOffset - previousDragOffset
                            
                            // Apply animation directly to headerOffset changes during drag for smoother feedback
                            withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8, blendDuration: 0)) {
                                headerOffset = max(min(headerOffset + deltaOffset, headerSize), 0)
                                print("headerOffset: \(headerOffset)")
                            }
                        }).onEnded({ value in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                // 드래그가 끝났을 때 headerOffset을 0으로 스냅하는 로직을 제거하거나 조건을 완화해야 합니다.
                                // 현재는 scrollOffset이 headerSize보다 작은 경우 headerOffset을 0으로 스냅하는 로직 때문에 문제가 발생할 수 있습니다.
                                
                                // 드래그 방향을 고려하여 헤더 스냅 로직 개선
                                if value.translation.height < 0 { // 위로 드래그 (헤더를 숨기려고 할 때)
                                    // headerOffset이 headerSize의 20%보다 많이 닫혀 있다면 완전히 닫기
                                    if headerOffset < (headerSize * 0.1) { // 20% 이상 닫혀 있다면
                                        headerOffset = 0
                                    } else { // 아니면 완전히 열기 (이 경우는 위로 드래그했음에도 불구하고 거의 열린 상태라면)
                                        headerOffset = headerSize
                                    }
                                } else { // 아래로 드래그 (헤더를 보이게 하려고 할 때)
                                    // headerOffset이 headerSize의 20%보다 많이 열려 있다면 완전히 열기
                                    if headerOffset > (headerSize * 0.9) { // 20% 이상 열려 있다면
                                        headerOffset = headerSize
                                    } else { // 아니면 완전히 닫기 (이 경우는 아래로 드래그했음에도 불구하고 거의 닫힌 상태라면)
                                        headerOffset = 0
                                    }
                                }
                                
                                // 스크롤 오프셋이 헤더 사이즈보다 작고, headerOffset이 0보다 클 때 0으로 스냅하는 로직 (기존 onScrollGeometryChange 로직)
                                // 이 부분이 드래그 종료 시점과 겹쳐서 원치 않는 동작을 유발할 수 있습니다.
                                // 만약 onEnded에서 이미 headerOffset을 결정했는데, 스크롤 변화가 바로 뒤따르면서 이를 다시 0으로 스냅한다면 문제가 됩니다.
                                // 따라서, onScrollGeometryChange에서 headerOffset을 0으로 스냅하는 조건을 더 엄격하게 하거나,
                                // 드래그 중에는 이 스냅 로직이 작동하지 않도록 수정해야 합니다.
                                
                                // 현재는 onEnded에서 결정한 값이 onScrollGeometryChange에 의해 덮어씌워질 가능성이 있습니다.
                                // onScrollGeometryChange 로직을 다음과 같이 수정해 보세요.
                                // if newValue < headerSize && headerOffset > 0 && currentDragOffset == 0 { ... }
                                // 이 부분은 드래그 중이 아닐 때만 작동하도록 `currentDragOffset == 0` 조건이 이미 있습니다.
                                // 하지만 `onEnded` 이후 `currentDragOffset`이 0으로 리셋되기 전에 스크롤이 업데이트되어 일시적으로 충돌할 수 있습니다.
                                // 이를 방지하기 위해 `onEnded` 시점의 스크롤 오프셋을 고려할 필요가 있습니다.
                            }
                            
                            /// Resetting Offset Data
                            currentDragOffset = 0
                            previousDragOffset = 0
                        })
                )
            }
        }
    }
    
    @ViewBuilder
    private func CombinedHeaderView() -> some View {
        VStack(spacing: 0) {
            // MARK: 최상단 고정 헤더
            fixedTopHeader
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: { newValue in
                    fixedTopHeaderSize = newValue
                }
            
            // MARK: 스크롤에 따라 오르내리는 헤더 (기존 header)
            VStack(spacing: 0) {
                header
                    .onGeometryChange(for: CGFloat.self) {
                        $0.size.height
                    } action: { newValue in
                        headerSize = newValue
                    }
            }
            .offset(y: -headerOffset) // 이 그룹에만 오프셋 적용
            .clipped() // 이 그룹만 클리핑
        }
        // CombinedHeaderView의 배경은 fixedTopHeader의 높이까지 포함하도록 수정
        .background {
            background
                .ignoresSafeArea()
                .offset(y: -headerOffset)
        }
        // By applying the clipped modifier at the bottom, the background will also be clipped. We need the background to include the safeArea edges, so let's apply the offset and clipped modifier before the background. Additionally, we should apply only the offset modifier to the background without the clipped modifier. This way, the background won't be clipped.
        // (하단에 clipped 수정자를 적용하면 배경도 잘립니다. 배경에 safeArea 모서리가 포함되어야 하므로, 배경보다 먼저 offset 수정자와 clipped 수정자를 적용하겠습니다. 또한, clipped 수정자를 적용하지 않고 offset 수정자만 배경에 적용해야 합니다. 이렇게 하면 배경이 잘리지 않습니다.)
    }
}

#Preview {
    ScrollContentView2()
}
