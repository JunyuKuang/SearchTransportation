//
//  RouteStationsTableViewController.swift
//  SearchTransportation
//
//  Created by Jonny on 1/1/17.
//  Copyright © 2017 Jonny. All rights reserved.
//

import UIKit

class RouteStationsTableViewController: TableViewController {

    @IBOutlet private var routeNameTextField: UITextField! {
        didSet {
            routeNameTextField.textColor = UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
        }
    }
    
    private enum SegueIdentifier: String {
        case presentAddStationsTableViewController
    }
    
    var route: BusRoute!
    
    var routeUpdateHandler: ((BusRoute) -> Void)?
    
    override var hintForEmptyTable: String {
        return "No Stations"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.isEditing = true
        routeNameTextField.text = route.name
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        routeNameTextField.resignFirstResponder()
        nameTextFieldHasSignificantChange()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let addStationsTableViewController = (segue.destination as? UINavigationController)?.viewControllers.first as? AddStationsTableViewController {
            addStationsTableViewController.excludedStations = route.stationSet
            addStationsTableViewController.addStationsHandler = { [weak self] newStations in
                guard let `self` = self else { return }
                self.route.stations += newStations
                self.routeUpdateHandler?(self.route)
                self.tableView.reloadData()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        hintLabel.isHidden = route.stations.count > 0
        return route.stations.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Basic", for: indexPath)
        let station = route.stations[indexPath.row]
        cell.textLabel?.text = station.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Stations"
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let stationToMove = route.stations.remove(at: sourceIndexPath.row)
        route.stations.insert(stationToMove, at: destinationIndexPath.row)
        routeUpdateHandler?(route)
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Remove From Route"
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        route.stations.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        routeUpdateHandler?(route)
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        guard routeNameTextField.isFirstResponder else { return }
        routeNameTextField.resignFirstResponder()
        nameTextFieldHasSignificantChange()
    }
    
    @IBAction private func routeNameTextFieldDidEndOnExit(_ sender: UITextField) {
        nameTextFieldHasSignificantChange()
    }
    
    private func nameTextFieldHasSignificantChange() {
        
        let newName = routeNameTextField.text ?? ""
        
        guard newName != route.name else { return }
        
        if newName.isEmpty {
            routeNameTextField.text = route.name
        }
        else if BusRoute.activeRoutes.contains(where: { $0.name == newName }) {
            routeNameTextField.text = route.name
            
            let controller = UIAlertController(title: "Route Name Existed", message: nil, preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            present(controller, animated: true)
        }
        else {
            route.name = newName
            routeUpdateHandler?(route)
        }
    }
    
}
