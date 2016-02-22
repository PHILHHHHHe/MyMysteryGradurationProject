//
//  SPControlPanel.swift
//  Sharpener
//
//  Created by Inti Guo on 2/20/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

class SPControlPanel: UIView {
    var upperBorder: UIView! {
        didSet {
            addSubview(upperBorder)
            upperBorder.translatesAutoresizingMaskIntoConstraints = false
            upperBorder.snp_makeConstraints { make in
                make.top.equalTo(self)
                make.centerX.equalTo(self)
                make.width.equalTo(self)
                make.height.equalTo(1)
            }
            upperBorder.backgroundColor = UIColor.spLightBorderColor()
        }
    }

    init() {
        super.init(frame: CGRectZero)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        upperBorder = UIView()
    }
}