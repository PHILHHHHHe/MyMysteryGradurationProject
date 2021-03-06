//
//  SPSVGGenerator.swift
//  Sharpener
//
//  Created by Inti Guo on 1/28/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation

class SPSVGGenerator {
    static let header: String = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n<svg width=\"750px\" height=\"1000px\" viewBox=\"0 0 750 1000\" version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\">"
    static let closer: String = "\n</svg>"
    
    func title(title: String) -> String {
        return "\t<title>\(title)</title>\n"
    }
    
    func createSVGFor(store: SPGeometricsStore, withCompletionHandler complete: (NSURL)->()) {
        var raw = SPSVGGenerator.header
        raw += title("Sharpener")
        for (i, shape) in store.shapeStore.enumerate() {
            var gelem = GroupElement(type: .Shape, id: "Shape-\(i)")
            var pelem = PathElement(id: "Shape-\(i)-Borders")
            for (_, curve) in shape.lines.enumerate() {
                for (k, p) in curve.vectorized.enumerate() {
                    if k == 0 { pelem.moveToPoint(p.anchorPoint); continue }
                    pelem.addCurveToPoint(p)
                }
            }
            gelem.subelements.append(pelem.string)
            raw += gelem.string
        }
        
        for (i, line) in store.lineStore.enumerate() {
            var gelem = GroupElement(type: .Line, id: "LineGroup-\(i)")
            for (j, curve) in line.lines.enumerate() {
                var pelem = PathElement(id: "Line-\(i)-Curve-\(j)")
                for (k, p) in curve.vectorized.enumerate() {
                    if k == 0 { pelem.moveToPoint(p.anchorPoint); continue }
                    pelem.addCurveToPoint(p)
                }
                gelem.subelements.append(pelem.string)
            }
            raw += gelem.string
        }
        raw += SPSVGGenerator.closer
        
        let fileHandler = SPSharpenerFileHandler()
        fileHandler.saveSVGString(raw) { url in
            complete(url)
        }
    }
    
    struct GroupElement {
        var id: String
        var fillMode: String = "evenodd"
        var fill: String = "none"
        var strokeWidth: CGFloat = 0
        var stroke: Bool = false
        var type: SPGeometricType
        var subelements = [String]()
        
        let head = "\n<g "
        let tail = "\n</g>"
        
        var string: String {
            var s = head + "id=\"" + id + "\" "
            if type == .Line {
                 s += "stroke=\"#000000\" stroke-width=\"\(strokeWidth)\" stroke-linecap=\"square\" fill=\"none\""
            } else {
                s += "stroke=\"none\" fill-rule=\"" + fillMode + "\" fill=\"#000000\""
            }
            s += ">"
            for sub in subelements {
                s += sub
            }
            s += tail
            return s
        }
        
        init(type: SPGeometricType, id: String) {
            self.type = type
            self.id = id
            switch type {
            case .Line:
                strokeWidth = 4
                stroke = true
            default: break
            }
        }
    }
    
    struct PathElement {
        var d: String
        var id: String
        
        let head = "<path "
        let tail = "></path>"
        
        init(id: String) { self.id = id; self.d = "" }
        mutating func moveToPoint(point: CGPoint) {
            d += "M\(point.x),\(point.y) "
        }
        mutating func addCurveToPoint(point: SPAnchorPoint) {
            guard point.controlPointA != nil || point.controlPointB != nil else {
                addLineToPoint(point.anchorPoint)
                return
            }
            let new = "C\(point.controlPointA!.x),\(point.controlPointA!.y) "
                    + "\(point.controlPointB!.x),\(point.controlPointB!.y) "
                    + "\(point.anchorPoint.x),\(point.anchorPoint.y) "
            d += new
        }
        mutating func addLineToPoint(point: CGPoint) {
            d += "L\(point.x),\(point.y) "
        }
        
        var string: String {
            return head + "d=\"" + d + "\" id=\"" + id + "\"" + tail
        }
    }
    
    struct CircleElement {
        var id: String
        var fill: String = "#000000"
        var cx: CGFloat
        var cy: CGFloat
        var r: CGFloat
        
        let head = "<path "
        let tail = "></path>"
        
        init(id: String, cx: CGFloat, cy: CGFloat, rx: CGFloat, r: CGFloat) {
            self.id = id
            self.cx = cx
            self.cy = cy
            self.r = r
        }
        
        var string: String {
            let d = "M\(cx),\(cy) m\(-r),0 a\(r)\(r) 0 1,0 \(r*2),0 a\(r)\(r) 0 1,0 \(-r*2),0"
            return head + "d=\"" + d + "\" id=\"" + id + "\" fill=\"" + fill + "\"" + tail
        }
    }
    
    struct RectElement {
        var id: String
        var fill: String = "#000000"
        var rect: CGRect
        
        let head = "<path "
        let tail = "></path>"
        
        init(id: String, rect: CGRect) {
            self.id = id
            self.rect = rect
        }
    }
}










