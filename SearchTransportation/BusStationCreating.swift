//
//  BusStationCreating.swift
//  SearchTransportation
//
//  Created by Jonny on 1/1/17.
//  Copyright © 2017 Jonny. All rights reserved.
//

import UIKit

protocol BusStationCreating {}

extension BusStationCreating where Self : UIViewController {
    
    func presentAlertForCreateStation(excludedStationNames: [String], handler: @escaping (BusStation?) -> Void) {
        
        let controller = UIAlertController(title: "Add Station", message: nil, preferredStyle: .alert)
        
        let notificationCenter = NotificationCenter.default
        var notificationTokens = [Any]()
        
        let doneAction = UIAlertAction(title: "Add", style: .default) { _ in
            notificationTokens.forEach(notificationCenter.removeObserver)
            
            let stationName = controller.textFields?.first?.text ?? ""
            guard !stationName.isEmpty else {
                handler(nil)
                return
            }
            
            if excludedStationNames.contains(stationName) {
                let controller = UIAlertController(title: "Station Name Existed", message: nil, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "Dismiss", style: .cancel) { _ in
                    handler(nil)
                })
                self.present(controller, animated: true)
            } else {
                handler(BusStation(name: stationName))
            }
        }
        doneAction.isEnabled = false
        controller.addAction(doneAction)
        controller.preferredAction = doneAction
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            notificationTokens.forEach(notificationCenter.removeObserver)
            handler(nil)
        }
        controller.addAction(cancelAction)
        
        controller.addTextField { textField in
            textField.enablesReturnKeyAutomatically = true
            textField.placeholder = "Station name (e.g. Sanlitun)"
            textField.returnKeyType = .done
            textField.autocapitalizationType = .words
            notificationTokens.append(notificationCenter.addObserver(forName: .UITextFieldTextDidChange, object: textField, queue: .main) { _ in
                doneAction.isEnabled = !controller.textFields!.contains(where: { ($0.text ?? "").isEmpty })
            })
        }
        
        present(controller, animated: true)
    }
    
}

