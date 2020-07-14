//
//  JonContextMenuView.swift
//  JonContextMenu
//
//  Created by Jonathan Martins on 10/09/2018.
//  Copyright © 2018 Surrey. All rights reserved.
//

import UIKit
import Foundation
import UIKit.UIGestureRecognizerSubclass

@objc public protocol JonContextMenuDelegate{
    func menuOpened()
    func menuClosed()
    func menuItemWasSelected(item:JonItem)
    func menuItemWasActivated(item:JonItem)
    func menuItemWasDeactivated(item:JonItem)
    func menuShouldBeShown(atPoint point: CGPoint) -> Bool
    func menuGetItems(atPoint point: CGPoint) -> [JonItem]
}

@objc open class JonContextMenu:NSObject{
    
    /// The items to be displayed
    var items:[JonItem] = []
    
    /// The delegate to notify the JonContextMenu host when an item is selected
    var delegate:JonContextMenuDelegate?
    
    /// The items' buttons default colour
    var buttonsDefaultColor:UIColor = .white
    
    /// The items' buttons active colour
    var buttonsActiveColor:UIColor = UIColor.init(hexString: "#c62828") // Red
    
    /// The items' icons default colour
    var iconsDefaultColor:UIColor?
    
    /// The items' icons active colour
    var iconsActiveColor:UIColor?
    
    /// The size of the title of the menu items
    var itemsTitleSize:CGFloat = 54
    
    /// The colour of the title of the menu items
    var itemsTitleColor:UIColor = UIColor.init(hexString: "#212121") // Dark Gray
    
    /// The colour of the touch location view
    var touchPointColor:UIColor = UIColor.init(hexString: "#212121") // Dark Gray
    
    override public init(){
        super.init()
    }
    
    /// Sets the items for the JonContextMenu
    @objc open func setItems(_ items: [JonItem])->JonContextMenu{
        self.items = items
        return self
    }
    
    /// Sets the delegate for the JonContextMenu
    @objc open func setDelegate(_ delegate: JonContextMenuDelegate?)->JonContextMenu{
        self.delegate = delegate
        return self
    }
    
    /// Sets the colour of the buttons for when there is no interaction
    @objc open func setItemsDefaultColorTo(_ colour: UIColor)->JonContextMenu{
        self.buttonsDefaultColor = colour
        return self
    }
    
    /// Sets the colour of the buttons for when there is interaction
    @objc open func setItemsActiveColorTo(_ colour: UIColor)->JonContextMenu{
        self.buttonsActiveColor = colour
        return self
    }
    
    /// Sets the colour of the icons for when there is no interaction
    @objc open func setIconsDefaultColorTo(_ colour: UIColor?)->JonContextMenu{
        self.iconsDefaultColor = colour
        return self
    }
    
    /// Sets the colour of the icons for when there is interaction
    @objc open func setIconsActiveColorTo(_ colour: UIColor?)->JonContextMenu{
        self.iconsActiveColor = colour
        return self
    }
    
    /// Sets the colour of the JonContextMenu items title
    @objc open func setItemsTitleColorTo(_ color: UIColor)->JonContextMenu{
        self.itemsTitleColor = color
        return self
    }
    
    /// Sets the size of the JonContextMenu items title
    @objc open func setItemsTitleSizeTo(_ size: CGFloat)->JonContextMenu{
        self.itemsTitleSize = size
        return self
    }
    
    /// Sets the colour of the JonContextMenu touch point
    @objc open func setTouchPointColorTo(_ color: UIColor)->JonContextMenu{
        self.touchPointColor = color
        return self
    }
    
    /// Builds the JonContextMenu
    @objc open func build()->Builder{
        return Builder(self)
    }
    
    @objc open class Builder:UILongPressGestureRecognizer{
        
        /// The selected menu item
        private var currentItem:JonItem?
        
        /// The JonContextMenu view
        private var contextMenuView:JonContextMenuView?
        
        /// The properties configuration to add to the JonContextMenu view
        private var properties:JonContextMenu!
        
        /// Indicates if there is a menu item active
        private var isItemActive = false
        
      @objc  init(_ properties:JonContextMenu){
            super.init(target: nil, action: nil)
            self.properties = properties
            addTarget(self, action: #selector(setupTouchAction))
        }
        
        /// Handle the touch events on the view
        @objc private func setupTouchAction(){
            guard let window = UIApplication.shared.keyWindow else{
                return
            }

            let location = self.location(in: window)
            switch self.state {
                case .began:
                    longPressBegan(on: location)
                case .changed:
                    longPressMoved(to: location)
                case .ended:
                    longPressEnded()
                case .cancelled:
                    longPressCancelled()
                default:
                    break
            }
        }
        
        /// Trigger the events for when the touch begins
        private func longPressBegan(on location:CGPoint) {
            showMenu(on: location)
        }
        
        // Triggers the events for when the touch ends
        private func longPressEnded() {
            if let currentItem = currentItem, currentItem.isActive{
                properties.delegate?.menuItemWasSelected(item: currentItem)
            }
            dismissMenu()
        }
        
        // Triggers the events for when the touch is cancelled
        private func longPressCancelled() {
            dismissMenu()
        }
        
        // Triggers the events for when the touch moves
        private func longPressMoved(to location:CGPoint) {
            if let currentItem = currentItem, currentItem.frame.contains(location){
                if !currentItem.isActive{
                    contextMenuView?.activate(currentItem)
                    properties.delegate?.menuItemWasActivated(item: currentItem)
                }
            }
            else{
                if let currentItem = currentItem, currentItem.isActive{
                    contextMenuView?.deactivate(currentItem)
                    properties.delegate?.menuItemWasDeactivated(item: currentItem)
                }
                for item in properties.items{
                    if item.frame.contains(location){
                        currentItem = item
                        break
                    }
                }
            }
        }
        
        func cancel() {
            properties.items = []
            self.isEnabled = false;
            self.isEnabled = true;
        }
        
        /// Creates the JonContextMenu view and adds to the Window
        private func showMenu(on location: CGPoint) {
            if let delegate = properties.delegate {
                if !delegate.menuShouldBeShown(atPoint: location) {
                    cancel()
                    return
                }
            }

            if properties.items.isEmpty {
                properties.items = properties.delegate?.menuGetItems(atPoint: location) ?? []
                if properties.items.isEmpty {
                    cancel()
                    return
                }
            }
            currentItem     = nil
            contextMenuView = JonContextMenuView(properties, touchPoint: location)

            guard let window = UIApplication.shared.keyWindow else{
                return
            }

            window.addSubview(contextMenuView!)
            properties.delegate?.menuOpened()
        }
        
        /// Removes the JonContextMenu view from the Window
        private func dismissMenu(){
            if let contextMenuView = contextMenuView {
                if let currentItem = currentItem{
                    contextMenuView.deactivate(currentItem)
                }
        
                contextMenuView.removeFromSuperview()
                properties.delegate?.menuClosed()
                self.contextMenuView = nil
                self.properties.items = []
            }
        }
    }
}
