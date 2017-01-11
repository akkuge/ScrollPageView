//
//  NormalAnimator.swift
//  PullToRefresh
//
//  Created by ZeroJ on 16/7/20.
//  Copyright © 2016年 ZeroJ. All rights reserved.
//

import UIKit

open class NormalAnimator: UIView {
    /// 设置imageView
    @IBOutlet fileprivate(set) weak var imageView: UIImageView!
    @IBOutlet fileprivate(set) weak var indicatorView: UIActivityIndicatorView!
    /// 设置state描述
    @IBOutlet fileprivate(set) weak var descroptionLabel: UILabel!
    /// 上次刷新时间label footer 默认为hidden, 可设置hidden=false开启
    @IBOutlet fileprivate(set) weak var lastTimelabel: UILabel!

    
    public typealias SetDescriptionClosure = (_ refreshState: RefreshViewState, _ refreshType: RefreshViewType) -> String
    public typealias SetLastTimeClosure = (_ date: Date) -> String
    
    
    /// 是否刷新完成后自动隐藏 默认为false
    /// 这个属性是协议定义的, 当写在class里面可以供外界修改, 如果写在extension里面只能是可读的
    open var isAutomaticlyHidden: Bool = false
    /// 这个key如果不指定或者为nil,将使用默认的key那么所有的未指定key的header和footer公用一个刷新时间
    open var lastRefreshTimeKey: String? = nil
    
    fileprivate var setupDesctiptionClosure: SetDescriptionClosure?
    fileprivate var setupLastTimeClosure: SetLastTimeClosure?
    /// 耗时
    fileprivate lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    /// 耗时
    fileprivate lazy var calendar: Calendar = Calendar.current
    
    open class func normalAnimator() -> NormalAnimator {
        let normalAnimator = Bundle.main.loadNibNamed(String(describing: NormalAnimator.self), owner: nil, options: nil)?.first as! NormalAnimator

        return normalAnimator
    }
    
    
    open func setupDescriptionForState(_ closure: @escaping SetDescriptionClosure) {
        setupDesctiptionClosure = closure
    }
    
    open func setupLastFreshTime(_ closure: @escaping SetLastTimeClosure) {
        setupLastTimeClosure = closure
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        indicatorView.isHidden = true
        indicatorView.hidesWhenStopped = true
    }
    
    //    public override func layoutSubviews() {
    //        super.layoutSubviews()
    //        print("layout--------------------------------------------")
    //    }
}

extension NormalAnimator: RefreshViewDelegate {
    
    public func refreshViewDidPrepare(_ refreshView: RefreshView, refreshType: RefreshViewType) {
        if refreshType == .header {
        } else {
            lastTimelabel.isHidden = true
            rotateArrowToUpAnimated(false)
        }
        setupLastTime()
        
    }
    
    public func refreshDidBegin(_ refreshView: RefreshView, refreshViewType: RefreshViewType) {
        indicatorView.isHidden = false
        indicatorView.startAnimating()
    }
    public func refreshDidEnd(_ refreshView: RefreshView, refreshViewType: RefreshViewType) {
        indicatorView.stopAnimating()
    }
    public func refreshDidChangeProgress(_ refreshView: RefreshView, progress: CGFloat, refreshViewType: RefreshViewType) {
        //        print(progress)
        
    }
    
    public func refreshDidChangeState(_ refreshView: RefreshView, fromState: RefreshViewState, toState: RefreshViewState, refreshViewType: RefreshViewType) {
        print(toState)
        
        setupDescriptionForState(toState, type: refreshViewType)
        switch toState {
        case .loading:
            imageView.isHidden = true
        case .normal:
            
            setupLastTime()
            imageView.isHidden = false
            ///恢复
            if refreshViewType == .header {
                rotateArrowToDownAnimated(false)
                
            } else {
                rotateArrowToUpAnimated(false)
            }
            
        case .pullToRefresh:
            if refreshViewType == .header {
                
                if fromState == .releaseToFresh {
                    rotateArrowToDownAnimated(true)
                }
                
            } else {
                
                if fromState == .releaseToFresh {
                    rotateArrowToUpAnimated(true)
                }
            }
            imageView.isHidden = false
            
        case .releaseToFresh:
            
            imageView.isHidden = false
            if refreshViewType == .header {
                rotateArrowToUpAnimated(true)
            } else {
                rotateArrowToDownAnimated(true)
            }
        }
    }
    
    fileprivate func rotateArrowToDownAnimated(_ animated: Bool) {
        let time = animated ? 0.2 : 0.0
        UIView.animate(withDuration: time, animations: {
            self.imageView.transform = CGAffineTransform.identity
            
        })
    }
    
    fileprivate func rotateArrowToUpAnimated(_ animated: Bool) {
        let time = animated ? 0.2 : 0.0
        UIView.animate(withDuration: time, animations: {
            self.imageView.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
            
        })
    }
    
    fileprivate func setupLastTime() {
        if lastTimelabel.isHidden {
            lastTimelabel.text = ""
        } else {
            guard let lastDate = lastRefreshTime else {
                lastTimelabel.text = "首次刷新"
                return
            }
            
            if let closure = setupLastTimeClosure {
                lastTimelabel.text = closure(lastDate as Date)
            } else {
                let lastComponent = (calendar as NSCalendar).components([.day, .year], from: lastDate as Date)
                let currentComponent = (calendar as NSCalendar).components([.day, .year], from: Date())
                var todayString = ""
                if lastComponent.day == currentComponent.day {
                    formatter.dateFormat = "HH:mm"
                    todayString = "今天 "
                    
                }
                else if lastComponent.year == currentComponent.year {
                    formatter.dateFormat = "MM-dd HH:mm"
                }
                else {
                    formatter.dateFormat = "yyyy-MM-dd HH:mm"
                }
                let timeString = formatter.string(from: lastDate as Date)
                lastTimelabel.text = "上次刷新时间:" + todayString + timeString
            }
        }
    }
    
    fileprivate func setupDescriptionForState(_ state: RefreshViewState, type: RefreshViewType) {
        if descroptionLabel.isHidden {
            descroptionLabel.text = ""
        } else {
            if let closure = setupDesctiptionClosure {
                descroptionLabel.text = closure(state, type)
            } else {
                switch state {
                case .normal:
                    descroptionLabel.text = "正常状态"
                case .loading:
                    descroptionLabel.text = "加载数据中..."
                case .pullToRefresh:
                    if type == .header {
                        descroptionLabel.text = "继续下拉刷新"
                    } else {
                        descroptionLabel.text = "继续上拉刷新"
                    }
                case .releaseToFresh:
                    descroptionLabel.text = "松开手刷新"
                    
                }
            }
        }
    }
    
}
