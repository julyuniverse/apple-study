//
//  ScrollContent2View.swift
//  AppleStudy
//
//  Created by July universe on 5/22/25.
//

import SwiftUI
import UIKit

// 데이터 모델
struct Item: Identifiable {
    let id: Int
    let title: String
}

// ScrollViewWithDirection 뷰
struct ScrollViewWithDirection: UIViewControllerRepresentable {
    @Binding var scrollDirection: String
    let items: [Item]

    func makeUIViewController(context: Context) -> ScrollViewController {
        let controller = ScrollViewController(scrollDirection: $scrollDirection, items: items)
        return controller
    }

    func updateUIViewController(_ uiViewController: ScrollViewController, context: Context) {
        uiViewController.updateScrollDirection($scrollDirection)
        uiViewController.updateItems(items)
    }
}

// ScrollViewController
class ScrollViewController: UIViewController, UIScrollViewDelegate {
    private var scrollView: UIScrollView!
    private var stackView: UIStackView!
    @Binding var scrollDirection: String
    private var lastOffset: CGPoint = .zero
    private var lastValidDirection: String = "정지"
    private var items: [Item] = []
    private var wasBouncing: Bool = false
    private var lastUpdateTime: Date = .distantPast // 마지막 방향 업데이트 시간
    private let debounceInterval: TimeInterval = 0.1 // 디바운스 간격 (100ms)

    init(scrollDirection: Binding<String>, items: [Item]) {
        self._scrollDirection = scrollDirection
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // UIScrollView 설정
        scrollView = UIScrollView()
        scrollView.delegate = self
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // UIStackView 설정
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // 초기 항목 렌더링
        updateStackView()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset
        let delta = currentOffset.y - lastOffset.y
        let currentTime = Date()

        // 바운스 영역 감지
        let contentHeight = scrollView.contentSize.height
        let viewHeight = scrollView.bounds.height
        let maxOffsetY = max(0, contentHeight - viewHeight)
        let isBouncingAtTop = currentOffset.y < 0
        let isBouncingAtBottom = currentOffset.y > maxOffsetY
        let isBouncing = isBouncingAtTop || isBouncingAtBottom

        // 디버깅 로그
        print("Offset: \(currentOffset.y), Delta: \(delta), isBouncingAtTop: \(isBouncingAtTop), isBouncingAtBottom: \(isBouncingAtBottom), LastValidDirection: \(lastValidDirection), wasBouncing: \(wasBouncing)")

        if isBouncing {
            // 바운스 영역에서는 lastValidDirection 유지
            if scrollDirection != lastValidDirection {
                scrollDirection = lastValidDirection
                logScrollDirection(lastValidDirection)
            }
            wasBouncing = true
        } else {
            // 정상 스크롤 영역
            if wasBouncing && abs(delta) < 1.0 {
                // 바운스에서 정상 영역으로 전환 시 작은 delta 무시
                if scrollDirection != lastValidDirection {
                    scrollDirection = lastValidDirection
                    logScrollDirection(lastValidDirection)
                }
            } else {
                // 유효한 스크롤 동작, 디바운스 적용
                let newDirection = if delta > 0.5 {
                    "위로 스크롤"
                } else if delta < -0.5 {
                    "아래로 스크롤"
                } else {
                    lastValidDirection // 기존 방향 유지
                }

                // 디바운스: 마지막 업데이트 후 100ms 이내에는 방향 변경 무시
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

    // 항목 업데이트
    func updateItems(_ newItems: [Item]) {
        self.items = newItems
        updateStackView()
    }

    private func updateStackView() {
        // 기존 뷰 제거
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        // 새 항목 추가
        for item in items {
            let label = UILabel()
            label.text = item.title
            label.textAlignment = .center
            label.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 100)
            stackView.addArrangedSubview(label)
        }
    }

    func updateScrollDirection(_ direction: Binding<String>) {
        self._scrollDirection = direction
    }

    // 스크롤 방향 로깅
    private func logScrollDirection(_ direction: String) {
        print("Scroll direction logged: \(direction) at \(Date())")
    }
}

struct ScrollContent2View: View {
    @State private var scrollDirection: String = "정지"
    @State private var items: [Item] = []

    var body: some View {
        ZStack {
            ScrollViewWithDirection(scrollDirection: $scrollDirection, items: items)
            VStack {
                Spacer()
                Text("스크롤 방향: \(scrollDirection)")
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            // 모의 데이터 생성
            items = (0..<50).map { Item(id: $0, title: "항목 \($0)") }
        }
    }
}

#Preview {
    ScrollContent2View()
}
