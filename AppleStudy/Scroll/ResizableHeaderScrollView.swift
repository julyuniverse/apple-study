//
//  ResizableHeaderScrollView.swift
//  AppleStudy
//
//  Created by mathmaster on 6/2/25.
//
// Starting with iOS 18, we can now simultaneously perform a gesture on a Scrollview, and it will work seamlessly with the scrollview. Prior to iOS 18, either the Scrollview or the Gesture would work, but not both simultaneously. By utilizing this feature, we can easily create a resizable sticky header that suits our specific requirements!
// (iOS 18부터 스크롤뷰에서 제스처를 동시에 실행할 수 있으며, 스크롤뷰와 원활하게 연동됩니다. iOS 18 이전에는 스크롤뷰와 제스처 중 하나만 작동했지만, 두 가지를 동시에 사용할 수는 없었습니다. 이 기능을 활용하면 특정 요구 사항에 맞는 크기 조절 가능한 고정 헤더를 쉽게 만들 수 있습니다!)

import SwiftUI

struct ResizableHeaderScrollView<Header: View, StickyHeader: View, Background: View, Content: View>: View {
    @ViewBuilder var header: Header
    @ViewBuilder var stickyHeader: StickyHeader
    /// Only for header background not for the entire view
    @ViewBuilder var background: Background
    @ViewBuilder var content: Content
    /// View Properties
    @State private var currentDragOffset: CGFloat = 0
    @State private var previousDragOffset: CGFloat = 0
    @State private var headerOffset: CGFloat = 0
    @State private var headerSize: CGFloat = 0
    @State private var stickyHeaderSize: CGFloat = .zero
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
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
        })
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .onChanged({ value in
                    /// Adjusting the minimun distanse value
                    /// Thus it starts from 0.
                    // The reason behind using the value "50" is that it initiates the resizing process after a certain period, allowing for scrolling. However, if you desire an instantaneous resizing effect, you can replace this value with "10," which is the same as the "minimumDistance" value.
                    // ("50" 값을 사용하는 이유는 일정 시간 후에 크기 조절 프로세스를 시작하여 스크롤을 가능하게 하기 때문입니다. 하지만 즉각적인 크기 조절 효과를 원하면 이 값을 "minimumDistance" 값과 동일한 "10"으로 바꿀 수 있습니다.)
                    let dragOffset = -max(0, abs(value.translation.height) - 50) * (value.translation.height < 0 ? -1 : 1)
                    
                    previousDragOffset = currentDragOffset
                    currentDragOffset = dragOffset
                    
                    let deltaOffset = (currentDragOffset - previousDragOffset).rounded()
                    
                    // We need to stop resizing the view to only the header height and make the "stickyHeader" content visible. To achieve this, we need to know the header height. With the help of the new "onGeometryChange" modifier, we can read the view's bounds and rect value.
                    // (뷰 크기를 헤더 높이로만 조정하는 것을 중단하고 "stickyHeader" 콘텐츠를 표시해야 합니다. 이를 위해서는 헤더 높이를 알아야 합니다. 새로운 "onGeometryChange" 수정자를 사용하면 뷰의 경계와 사각형 값을 읽을 수 있습니다.)
                    headerOffset = max(min(headerOffset + deltaOffset, headerSize), 0)
                }).onEnded({ _ in
                    // When a user stops interacting while resizing the view, the view will appear like this. To resolve this issue, we need to write a condition that evaluates and adjusts the headerOffset value when the gesture ends.
                    // (사용자가 뷰 크기를 조절하는 동안 상호작용을 중단하면 뷰가 이렇게 표시됩니다. 이 문제를 해결하려면 제스처가 종료될 때 headerOffset 값을 평가하고 조정하는 조건을 작성해야 합니다.)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if headerOffset > (headerSize * 0.5) && scrollOffset > headerSize {
                            headerOffset = headerSize
                        } else {
                            headerOffset = 0
                        }
                    }
                    
                    /// Resetting Offset Data
                    currentDragOffset = 0
                    previousDragOffset = 0
                })
        )
        .safeAreaInset(edge: .top, spacing: 0) {
            CombinedHeaderView()
        }
    }
    
    @ViewBuilder
    private func CombinedHeaderView() -> some View {
        VStack(spacing: 0) {
            header
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: { newValue in
                    headerSize = newValue
                }
            
            stickyHeader
        }
        .offset(y: -headerOffset)
        .clipped()
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
    ScrollContentView3()
}
