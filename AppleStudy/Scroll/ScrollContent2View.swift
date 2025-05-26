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
class ScrollViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private var tableView: UITableView!
    @Binding var scrollDirection: String
    private var lastOffset: CGPoint = .zero
    private var lastValidDirection: String = "정지"
    private var items: [Item] = []
    private var wasBouncing: Bool = false
    private var lastUpdateTime: Date = .distantPast
    private let debounceInterval: TimeInterval = 0.1 // 100ms 디바운스
    private let deltaThreshold: CGFloat = 0.5 // 방향 변경 임계값
    
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
        
        // UITableView 설정
        tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // 초기 데이터 로드
        tableView.reloadData()
    }
    
    // UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row].title
        cell.textLabel?.textAlignment = .center
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100 // 항목 높이
    }
    
    // UIScrollViewDelegate (UITableView는 UIScrollView 기반)
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
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // 정지 상태 설정 제거
        if !decelerate {
            print("Dragging ended without deceleration, maintaining direction: \(lastValidDirection)")
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // 정지 상태 설정 제거
        print("Deceleration ended, maintaining direction: \(lastValidDirection)")
    }
    
    // 항목 업데이트
    func updateItems(_ newItems: [Item]) {
        self.items = newItems
        tableView.reloadData()
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
