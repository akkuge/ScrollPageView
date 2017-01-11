//
//  PageViewController.swift
//  ScrollViewController
//
//  Created by ZeroJ on 16/8/31.
//  Copyright © 2016年 ZeroJ. All rights reserved.
//

import UIKit

// MARK: PageTableViewDelegate
protocol PageViewDelegate: class {
    func scrollViewIsScrolling(_ scrollView: UIScrollView)
}


class PageViewController: UIViewController, UIScrollViewDelegate {
    // 代理
    weak var delegate: PageViewDelegate?
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.scrollViewIsScrolling(scrollView)
    }
}
