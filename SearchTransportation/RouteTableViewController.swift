//
//  RouteTableViewController.swift
//  SearchTransportation
//
//  Created by Jonny on 1/1/17.
//  Copyright © 2017 Jonny. All rights reserved.
//

import UIKit

class RouteTableViewController: TableViewController {
    
    private var routes = [BusRoute]()
    
    private var searchedRoutes = [BusRoute]()
    
    override var hintForEmptyTable: String {
        return "No Routes"
    }
    
    override var searchBarPlaceholder: String? {
        return "Routes, Stations"
    }
    
    override var isSearchable: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(busLinesDidChange), name: NSNotification.Name.busRoutesDidChange, object: nil)
        busLinesDidChange()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let routeStationsTableViewController = segue.destination as? RouteStationsTableViewController,
            let cell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: cell) {
            
            routeStationsTableViewController.route = searchController.isActive ? searchedRoutes[indexPath.row] : routes[indexPath.row]
            routeStationsTableViewController.routeUpdateHandler = { route in
                if let index = BusRoute.activeRoutes.index(of: route) {
                    BusRoute.activeRoutes[index] = route
                }
            }
        }
    
        super.prepare(for: segue, sender: sender) // dismiss search controller if needed
    }
    
    func busLinesDidChange() {
        routes = BusRoute.activeRoutes.sorted { $0.name < $1.name }
        
        if searchController.isActive {
            updateSearchResults(for: searchController)
        } else {
            tableView.reloadData()
        }
    }
    
    override func updateSearchResults(for searchController: UISearchController) {
        super.updateSearchResults(for: searchController)
        
        if searchController.isActive {
            let searchText = searchController.searchBar.text ?? ""
            
            if searchText.isEmpty {
                searchedRoutes = routes
            } else {
                searchedRoutes = routes.filter { $0.name.range(of: searchText, options: .caseInsensitive) != nil || $0.stationSet.contains { $0.name.range(of: searchText, options: .caseInsensitive) != nil } }
            }
        } else {
            searchedRoutes.removeAll()
        }
        
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let count = searchController.isActive ? searchedRoutes.count : routes.count
        hintLabel.isHidden = count > 0
        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Subtitle", for: indexPath)
        let route = searchController.isActive ? searchedRoutes[indexPath.row] : routes[indexPath.row]
        
        cell.textLabel?.text = route.name
        cell.detailTextLabel?.text = route.stations.map { $0.name } .joined(separator: " - ")
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        let route = searchController.isActive ? searchedRoutes[indexPath.row] : routes[indexPath.row]
        if let index = BusRoute.activeRoutes.index(of: route) {
            BusRoute.activeRoutes.remove(at: index)
        }
    }
    
    //    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    //
    //    }
    
    @IBAction func addButtonItemDidTap(_ sender: UIBarButtonItem) {
        
        let controller = UIAlertController(title: "Add Route", message: nil, preferredStyle: .alert)
        
        let notificationCenter = NotificationCenter.default
        var notificationTokens = [Any]()
        
        let doneAction = UIAlertAction(title: "Add", style: .default) { _ in
            notificationTokens.forEach(notificationCenter.removeObserver)
            
            let stationName = controller.textFields?.first?.text ?? ""
            
            if BusRoute.activeRoutes.contains(where: { $0.name == stationName }) {
                let controller = UIAlertController(title: "Route Name Existed", message: nil, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                self.present(controller, animated: true)
            } else {
                BusRoute.activeRoutes.append(BusRoute(name: stationName))
            }
        }
        doneAction.isEnabled = false
        controller.addAction(doneAction)
        controller.preferredAction = doneAction
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            notificationTokens.forEach(notificationCenter.removeObserver)
        }
        controller.addAction(cancelAction)
        
        controller.addTextField { textField in
            textField.enablesReturnKeyAutomatically = true
            textField.placeholder = "Route name (e.g. 132)"
            textField.returnKeyType = .done
            textField.autocapitalizationType = .words
            notificationTokens.append(notificationCenter.addObserver(forName: .UITextFieldTextDidChange, object: textField, queue: .main) { _ in
                doneAction.isEnabled = !controller.textFields!.contains(where: { ($0.text ?? "").isEmpty })
            })
        }
        
        present(controller, animated: true)
        
    }
    
}
