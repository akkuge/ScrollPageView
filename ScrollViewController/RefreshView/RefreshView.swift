//
//  RefreshViewDelegate.swift
//  PullToRefresh
//
//  Created by ZeroJ on 16/7/20.
//  Copyright © 2016年 ZeroJ. All rights reserved.
//

import UIKit
public enum RefreshViewState {
    /// 正在加载状态
    case loading
    /// 正常状态
    case normal
    /// 下拉状态
    case pullToRefresh
    /// 松开手即进入刷新状态
    case releaseToFresh
}


public enum RefreshViewType {
    case header, footer
}

public protocol RefreshViewDelegate {
    /// 你应该为每一个header或者footer设置一个不同的key来保存时间, 否则将公用同一个key使用相同的时间
    var lastRefreshTimeKey: String? { get }
    /// 是否刷新完成后自动隐藏 默认为false
    var isAutomaticlyHidden: Bool { get }
    /// 上次刷新时间, 有默认赋值和返回
    var lastRefreshTime: Date? { get set }
    /// repuired 三个必须实现的代理方法
    
    /// 开始进入刷新(loading)状态, 这个时候应该开启自定义的(动画)刷新
    func refreshDidBegin(_ refreshView: RefreshView, refreshViewType: RefreshViewType)
    
    /// 刷新结束状态, 这个时候应该关闭自定义的(动画)刷新
    func refreshDidEnd(_ refreshView: RefreshView, refreshViewType: RefreshViewType)
    
    /// 刷新状态变为新的状态, 这个时候可以自定义设置各个状态对应的属性
    func refreshDidChangeState(_ refreshView: RefreshView, fromState: RefreshViewState, toState: RefreshViewState, refreshViewType: RefreshViewType)
    
    /// optional 两个可选的实现方法
    /// 允许在控件添加到scrollView之前的准备
    func refreshViewDidPrepare(_ refreshView: RefreshView, refreshType: RefreshViewType)
    
    /// 拖拽的进度, 可用于自定义实现拖拽过程中的动画
    func refreshDidChangeProgress(_ refreshView: RefreshView, progress: CGFloat, refreshViewType: RefreshViewType)
    
}

/// default doing
extension RefreshViewDelegate {
    public func refreshViewDidPrepare(_ refreshView: RefreshView, refreshType: RefreshViewType) { }
    public func refreshDidChangeProgress(_ refreshView: RefreshView, progress: CGFloat, refreshViewType: RefreshViewType) { }
    public var isAutomaticlyHidden: Bool { return false }
    
    public var lastRefreshTime: Date? {
        get {
            return UserDefaults.standard.object(forKey: lastRefreshTimeKey ?? RefreshView.ConstantValue.commonRefreshTimeKey) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: lastRefreshTimeKey ?? RefreshView.ConstantValue.commonRefreshTimeKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    public var lastRefreshTimeKey: String? {
        return nil
    }
}


open class RefreshView: UIView {
    /// KVO Constant
    struct ConstantValue {
        static var RefreshViewContext: UInt8 = 0
        static let ScrollViewContentOffsetPath = "contentOffset"
        static let ScrollViewContentSizePath = "contentSize"
        static let commonRefreshTimeKey = "ZJCommonRefreshTimeKey"
        static let LastRefreshTimeKey = ProcessInfo().globallyUniqueString
        
    }
    ///
    typealias RefreshHandler = (Void) -> Void
    // MARK: - internal property
    var canBegin = false {
        didSet {
            if canBegin == oldValue { return }
            if canBegin {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }
    
    // MARK: - private property
    fileprivate var refreshViewState: RefreshViewState = .normal {
        didSet {
            if refreshViewState == .normal {
                isHidden = refreshAnimator.isAutomaticlyHidden
            }
            else { isHidden = false }
            
            if refreshViewState != oldValue {
                if refreshViewState == .loading {
//                    print(refreshAnimator.lastRefreshTimeKey)
                    refreshAnimator.lastRefreshTime = Date()
                    
                }
                refreshAnimator.refreshDidChangeState(self, fromState: oldValue, toState: refreshViewState, refreshViewType: refreshViewType)
                
            }
        }
    }
    
    /// action handler
    fileprivate let refreshHandler: RefreshHandler
    /// handler refresh !! must be UIView which conform to RefreshViewDelegate protocol
    fileprivate var refreshAnimator: RefreshViewDelegate
    /// header or footer
    fileprivate var refreshViewType: RefreshViewType = .header
    /// to distinguish if is refreshing
    fileprivate var isRefreshing = false
    /// to distinguish if dragging begins
    fileprivate var isGestureBegin = false
    fileprivate var offPartHeight = CGFloat(0)
    fileprivate var beginAnimatingOffsetY: CGFloat = 0
    /// 标注结束的动画是否执行完成
    fileprivate var isAnimating = false
    /// store it to reset scrollView' after animating
    fileprivate var scrollViewOriginalValue:(bounces: Bool, contentInset: UIEdgeInsets, contentOffset: CGPoint) = (false, UIEdgeInsets(), CGPoint())
    /// superView
    fileprivate weak var scrollView: UIScrollView? {
        return self.superview as? UIScrollView
    }
    
    //MARK: - life cycle
    ///
    init<Animator:UIView>(frame: CGRect, refreshType: RefreshViewType, refreshAnimator: Animator, refreshHandler: @escaping RefreshHandler) where Animator: RefreshViewDelegate {
        self.refreshViewType = refreshType
        self.refreshAnimator = refreshAnimator
        self.refreshHandler = refreshHandler
        super.init(frame: frame)
        addSubview(refreshAnimator)
        /// needed
        autoresizingMask = .flexibleWidth
        addConstraint()
        /// animator can prepare to do something
        self.refreshAnimator.refreshViewDidPrepare(self, refreshType: self.refreshViewType)
        ///
        isHidden = refreshAnimator.isAutomaticlyHidden
    }
    ///
    fileprivate func addConstraint() {
        guard let refreshAnimatorView = refreshAnimator as? UIView else { return }
        let leading = NSLayoutConstraint(item: refreshAnimatorView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0)
        let top = NSLayoutConstraint(item: refreshAnimatorView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0)
        let trailing = NSLayoutConstraint(item: refreshAnimatorView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        let bottom = NSLayoutConstraint(item: refreshAnimatorView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        
        refreshAnimatorView.translatesAutoresizingMaskIntoConstraints = false
        addConstraints([leading, top, trailing, bottom])
    }
    ///
    required public init?(coder aDecoder: NSCoder) {
        fatalError("there is no need to suport xib")
    }
    
    deinit {
        removeObserverOf(scrollView)
    }
    
    override open func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        removeObserverOf(scrollView)
        
        if let newScrollView = newSuperview as? UIScrollView {
            ///  can drag anytime
            newScrollView.alwaysBounceVertical = true
            addObserverOf(newScrollView)
            scrollViewOriginalValue = (newScrollView.bounces, newScrollView.contentInset, newScrollView.contentOffset)
            if refreshViewType == .footer {// reset frame
                self.frame.origin.y = newScrollView.contentSize.height
            }
        }
    }
    
}

extension RefreshView {
    
    fileprivate func startAnimation() {
        guard let validScrollView = scrollView else { return }
        validScrollView.bounces = false
        isRefreshing = true
        if isHidden { isHidden = false }
        /// may update UI
        DispatchQueue.main.async(execute: {[weak self] in
            guard let validSelf = self else { return }
            
            UIView.animate(withDuration: 0.25, animations: {
                if validSelf.refreshViewType == .header {
                    validScrollView.contentInset.top = validSelf.scrollViewOriginalValue.contentInset.top + validSelf.bounds.height
                } else {
                    let offPartHeight = validScrollView.contentSize.height - validSelf.heightOfContentOnScreenOfScrollView(validScrollView)
                    /// contentSize改变的时候设置的self.y不同导致不同的结果
                    /// 所有内容高度>屏幕上显示的内容高度
                    let notSureBottom = validSelf.scrollViewOriginalValue.contentInset.bottom + validSelf.bounds.height
                    validScrollView.contentInset.bottom = offPartHeight>=0 ? notSureBottom : notSureBottom - offPartHeight // 加上
                    
                }
                
                }, completion: { (_) in
                    /// 这个时候才正式刷新
                    validScrollView.bounces = true
                    validSelf.isGestureBegin = false
                    validSelf.refreshViewState = .loading
                    validSelf.refreshAnimator.refreshDidBegin(validSelf, refreshViewType: validSelf.refreshViewType)
                    validSelf.refreshHandler()
            })
            
        })
        
    }
    
    fileprivate func stopAnimation() {
        guard let validScrollView = scrollView else { return }
        if !isRefreshing { return }
        isRefreshing = false
        isAnimating = true
//        print("endAnimation ---    \(scrollViewOriginalValue.contentInset.top)")

        DispatchQueue.main.async(execute: {[weak self] in
            guard let validSelf = self else { return }
            
            UIView.animate(withDuration: 0.25, animations: {
                if validSelf.refreshViewType == .header {
                    validScrollView.contentInset.top = validSelf.scrollViewOriginalValue.contentInset.top
                } else {
                    
                    validScrollView.contentInset.bottom = validSelf.scrollViewOriginalValue.contentInset.bottom
                }
                
                }, completion: { (_) in
                    
                    // refresh end
                    validScrollView.bounces = validSelf.scrollViewOriginalValue.bounces
//                    print("endAnimation ---    \(self!.scrollView?.contentInset.top)")
                    validSelf.isAnimating = false
                    validSelf.refreshAnimator.refreshDidChangeProgress(validSelf, progress: 1.0, refreshViewType: validSelf.refreshViewType)
                    validSelf.refreshAnimator.refreshDidEnd(validSelf, refreshViewType: validSelf.refreshViewType)
                    validSelf.refreshViewState = .normal
            })
            
        })
        
    }
    
}

// MARK: - KVO
extension RefreshView {
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &ConstantValue.RefreshViewContext {
            
            if keyPath == ConstantValue.ScrollViewContentSizePath {
                
                guard let validScrollView = scrollView,
                    let oldSize = (change?[NSKeyValueChangeKey.oldKey] as AnyObject).cgSizeValue,
                    let newSize = (change?[NSKeyValueChangeKey.newKey] as AnyObject).cgSizeValue, oldSize != newSize &&
                        refreshViewType == .footer
                    else { return }
                
                /// 设置刷新控件self的位置
                let contentOnScreenHeight = heightOfContentOnScreenOfScrollView(validScrollView)
                /// 添加在屏幕"外面"
                
                self.frame.origin.y = max(newSize.height, contentOnScreenHeight)
                //                print("old--*\(oldSize.height)--------*\(newSize.height)")
                
            }
            else if keyPath == ConstantValue.ScrollViewContentOffsetPath {
                
                if let validScrollView = scrollView, object as? UIScrollView == validScrollView {
                    
                    if refreshViewType == .header {
                        adjustHeaderWhenScrollViewIsScrolling(validScrollView)
                    } else {
                        adjustFooterWhenScrollViewIsScrolling(validScrollView)
                    }
                }
            }
            else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
                
            }
            
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    fileprivate func adjustFooterWhenScrollViewIsScrolling(_ scrollView: UIScrollView) {
        
        if isRefreshing {/**正在刷新直接返回*/ return }
        
        scrollViewOriginalValue.contentInset = scrollView.contentInset
        if scrollView.panGestureRecognizer.state == .began {// 手势拖拽才能进入下拉状态
            isGestureBegin = true
            /// 超出屏幕的内容高度
            offPartHeight = frame.origin.y - scrollView.bounds.height
            beginAnimatingOffsetY = offPartHeight>0 ? offPartHeight : -scrollViewOriginalValue.contentInset.top
            return
        }
        
        if !isGestureBegin {/**没有拖拽直接返回*/ return }
        
        // 已经进入拖拽状态, 进行相关操作

//        print("\(offPartHeight) -----* \(beginAnimatingOffsetY) --- *\(scrollView.contentOffset.y)")
        if scrollView.contentOffset.y < beginAnimatingOffsetY {/**底部视图(隐藏)并且还没到显示的临界点*/ return }
        let progress = (scrollView.contentOffset.y - beginAnimatingOffsetY) / self.bounds.height
        
        adjustRefreshViewWithProgress(progress, scrollView: scrollView)
        
    }
    
    fileprivate func adjustHeaderWhenScrollViewIsScrolling(_ scrollView: UIScrollView) {
        if isRefreshing {/**正在刷新直接返回*/
            /// 需要处理这个时候滚动时sectionHeader悬停的问题
            /// 参照MJRefresh
            var insetsTop: CGFloat = 0
            if scrollView.contentOffset.y > -scrollViewOriginalValue.contentInset.top {
                insetsTop = scrollViewOriginalValue.contentInset.top
            } else {
                insetsTop = -scrollView.contentOffset.y
            }
            
            insetsTop = min(scrollViewOriginalValue.contentInset.top + self.bounds.height, insetsTop)
            scrollView.contentInset.top = insetsTop
//            print("--------******   \(scrollView.contentInset.top)")
            return
        }
        /// 不在刷新状态的时候都随时记录原始的contentInset
        /// 刷新状态的时候不能记录为原始的
        if isAnimating {/**stop动画还未执行完成*/ return }
        scrollViewOriginalValue.contentInset = scrollView.contentInset
        
        if scrollView.panGestureRecognizer.state == .began {// 手势拖拽才能进入下拉状态
            isGestureBegin = true
            return
        }
        
        
        if !isGestureBegin {/**没有拖拽直接返回*/ return }
        
        
        //        print("\(scrollView.contentOffset.y)------*\(-scrollViewOriginalValue.contentInset.top)")
        if scrollView.contentOffset.y > -scrollViewOriginalValue.contentInset.top {/**头部视图(隐藏)并且还没到显示的临界点*/ return }
        
        // 已经进入拖拽状态, 进行相关操作
        let progress = (-scrollViewOriginalValue.contentInset.top - scrollView.contentOffset.y) / self.bounds.height
        
        adjustRefreshViewWithProgress(progress, scrollView: scrollView)
    }
    
    fileprivate func adjustRefreshViewWithProgress(_ progress: CGFloat, scrollView: UIScrollView) {
        
//        print(progress)
        
        if scrollView.isTracking {
            
            if progress >= 1.0 {
                refreshViewState = .releaseToFresh
                
            } else if progress <= 0.0 {
                refreshViewState = .normal
            } else {
                refreshViewState = .pullToRefresh
            }
            
        }
        else if refreshViewState == .releaseToFresh {// releaseToFreah 2 refresh
            canBegin = true// begin refresh
        }
        else {// release
            if progress <= 0.0 {
                refreshViewState = .normal
            }
            
        }
        
        var actualProgress = min(1.0, progress)
        actualProgress = max(0.0, actualProgress)
        refreshAnimator.refreshDidChangeProgress(self, progress: actualProgress, refreshViewType: refreshViewType)
    }
    
    /// 显示在屏幕上的内容高度
    fileprivate func heightOfContentOnScreenOfScrollView(_ scrollView: UIScrollView) -> CGFloat {
        return scrollView.bounds.height - scrollViewOriginalValue.contentInset.top - scrollViewOriginalValue.contentInset.bottom
    }
    
    
    fileprivate func addObserverOf(_ scrollView: UIScrollView?) {
        scrollView?.addObserver(self, forKeyPath: ConstantValue.ScrollViewContentOffsetPath, options: .initial, context: &ConstantValue.RefreshViewContext)
        scrollView?.addObserver(self, forKeyPath: ConstantValue.ScrollViewContentSizePath, options: [.old, .new], context: &ConstantValue.RefreshViewContext)
        
    }
    
    fileprivate func removeObserverOf(_ scrollView: UIScrollView?) {
        scrollView?.removeObserver(self, forKeyPath: ConstantValue.ScrollViewContentOffsetPath, context: &ConstantValue.RefreshViewContext)
        scrollView?.removeObserver(self, forKeyPath: ConstantValue.ScrollViewContentSizePath, context: &ConstantValue.RefreshViewContext)
        
    }
}
