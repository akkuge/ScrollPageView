//
//  SelectionCollectionViewCell.swift
//  ScrollViewController
//
//  Created by jasnig on 16/5/1.
//  Copyright © 2016年 ZeroJ. All rights reserved.
// github: https://github.com/jasnig
// 简书: http://www.jianshu.com/users/fb31a3d1ec30/latest_articles

//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import UIKit
enum SelectionBtnState {
    case normal
    case selected
}
class SelectionCollectionViewCell: UICollectionViewCell {
    
    typealias BtnAction = (_ btn: UIButton) -> Void

    @IBOutlet weak var deleteBtn: UIButton!

    @IBOutlet weak var selectionBtn: UIButton!
    var selectedAction: BtnAction?
    var deleteAction: BtnAction?
    
    @IBAction func deletebtnOnClick(_ sender: UIButton) {
        deleteAction?(sender)
    }
    
    @IBAction func selectionBtnOnClick(_ sender: UIButton) {
        selectedAction?(sender)
    }
    
    var title: String = "" {
        didSet {
            selectionBtn.setTitle(title, for: UIControlState())
        }
    }
    var state: SelectionBtnState = .normal {
        didSet {
            switch state {
            case .normal:
                deleteBtn.isHidden = true
            default:
                deleteBtn.isHidden = false
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        deleteBtn.isHidden = true
        selectionBtn.setBackgroundImage(resizeImage(), for: UIControlState())
        selectionBtn.adjustsImageWhenHighlighted = false
    }
    
    func resizeImage() -> UIImage {
        var image = UIImage(named: "channel_grid_circle")!
        let inset = UIEdgeInsets(top: 15.0, left: 10.0, bottom: 15.0, right: 10.0)
        image = image.resizableImage(withCapInsets: inset, resizingMode: .stretch)
        return image
    }

}
