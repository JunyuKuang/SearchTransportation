//
//  StationsManagementTableViewController.swift
//  SearchTransportation
//
//  Created by Jonny on 1/1/17.
//  Copyright © 2017 Jonny. All rights reserved.
//

import UIKit

class StationsManagementTableViewController: StationTableViewController, BusStationCreating {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.tableView.deselectRow(at: indexPath, animated: true)
        })
        
        controller.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.deleteStation(at: indexPath)
        })
        controller.addAction(UIAlertAction(title: "Rename", style: .default) { _ in
            self.requestRenameStation(at: indexPath)
        })
        
        if let popover = controller.popoverPresentationController {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
        }
        
        (presentedViewController ?? self).present(controller, animated: true)
        
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { _, indexPath in
            self.deleteStation(at: indexPath)
        }
        let renameAction = UITableViewRowAction(style: .normal, title: "Rename") { _, indexPath in
            tableView.setEditing(false, animated: true)
            self.requestRenameStation(at: indexPath)
        }
        return [deleteAction, renameAction]
    }
    
    @IBAction private func addButtonItemDidTap(_ sender: UIBarButtonItem) {
        
        presentAlertForCreateStation(excludedStationNames: BusStation.activeStations.map { $0.name }) { station in
            guard let station = station else { return }
            BusStation.activeStations.append(station)
        }
    }
    
    private func requestRenameStation(at indexPath: IndexPath) {
        
        let station = searchController.isActive ? searchedBusStations[indexPath.row] : busStations[indexPath.row]
        
        let controller = UIAlertController(title: "Rename", message: nil, preferredStyle: .alert)
        
        let notificationCenter = NotificationCenter.default
        var notificationTokens = [Any]()
        
        let doneAction = UIAlertAction(title: "Rename", style: .default) { _ in
            
            self.tableView.deselectRow(at: indexPath, animated: true)
            notificationTokens.forEach(notificationCenter.removeObserver)
            
            let newStationName = controller.textFields?.first?.text ?? ""
            guard !newStationName.isEmpty else { return }
            
            if newStationName == station.name {
                return
            }
            else if BusStation.activeStations.map({ $0.name }).contains(newStationName) {
                let controller = UIAlertController(title: "Station Name Existed", message: nil, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "Dismiss", style: .cancel) { _ in
                    self.tableView.deselectRow(at: indexPath, animated: true)
                })
                (self.presentedViewController ?? self).present(controller, animated: true)
            }
            else if let index = BusStation.activeStations.index(of: station) {
                // update stations
                BusStation.activeStations[index].name = newStationName
                
                // update routes
                var activeRoutes = BusRoute.activeRoutes
                for routeIndex in 0 ..< activeRoutes.count {
                    if let stationIndex = activeRoutes[routeIndex].stations.index(of: station) {
                        activeRoutes[routeIndex].stations[stationIndex].name = newStationName
                    }
                }
                BusRoute.activeRoutes = activeRoutes
            }
        }
        doneAction.isEnabled = false
        controller.addAction(doneAction)
        controller.preferredAction = doneAction
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.tableView.deselectRow(at: indexPath, animated: true)
            notificationTokens.forEach(notificationCenter.removeObserver)
        }
        controller.addAction(cancelAction)
        
        controller.addTextField { textField in
            textField.enablesReturnKeyAutomatically = true
            textField.text = station.name
            textField.placeholder = "Station name (e.g. Sanlitun)"
            textField.returnKeyType = .done
            textField.autocapitalizationType = .words
            notificationTokens.append(notificationCenter.addObserver(forName: .UITextFieldTextDidChange, object: textField, queue: .main) { _ in
                doneAction.isEnabled = !controller.textFields!.contains(where: { ($0.text ?? "").isEmpty })
            })
        }
        
        (presentedViewController ?? self).present(controller, animated: true)
    }
    
    private func deleteStation(at indexPath: IndexPath) {
        
        let stationToDelete = searchController.isActive ? searchedBusStations[indexPath.row] : busStations[indexPath.row]
        guard let index = BusStation.activeStations.index(of: stationToDelete) else { return }
        
        // update stations
        BusStation.activeStations.remove(at: index)
        
        // update routes
        var routes = BusRoute.activeRoutes
        
        for i in 0 ..< routes.count {
            if let index = routes[i].stations.index(of: stationToDelete) {
                routes[i].stations.remove(at: index)
            }
        }
        
        BusRoute.activeRoutes = routes
    }
}

