//
//  RouteAddStationsTableViewController.swift
//  SearchTransportation
//
//  Created by Jonny on 1/1/17.
//  Copyright © 2017 Jonny. All rights reserved.
//

import UIKit

class AddStationsTableViewController: TableViewController, BusStationCreating {
    
    @IBOutlet private var saveButtonItem: UIBarButtonItem!
    
    override var isSearchable: Bool {
        return true
    }
    
    override var searchBarPlaceholder: String? {
        return "Stations"
    }
    
    private var busStations = [BusStation]()
    
    private var searchedBusStations = [BusStation]()
    
    private var selectedBusStations = [BusStation]() {
        didSet {
            saveButtonItem.isEnabled = selectedBusStations.count > 0
            
            switch selectedBusStations.count {
            case 0:
                title = "Select Stations"
            case 1:
                title = "Add 1 Station"
            default:
                title = "Add \(selectedBusStations.count) Stations"
            }
        }
    }
    
    var excludedStations = Set<BusStation>()
    
    var addStationsHandler: (([BusStation]) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(busStationsDidChange), name: .busStationsDidChange, object: nil)
        busStationsDidChange()
        
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : UIFont.monospacedDigitSystemFont(ofSize: 17, weight: UIFontWeightSemibold)]
        tableView.isEditing = true
        selectedBusStations = []
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.navigationBar.titleTextAttributes = nil
    }
    
    func busStationsDidChange() {
        busStations = BusStation.activeStations.filter { !excludedStations.contains($0) } .sorted { $0.name < $1.name }
        
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
                searchedBusStations = busStations
            } else {
                searchedBusStations = busStations.filter { $0.name.contains(searchText) }
            }
        } else {
            searchedBusStations.removeAll()
        }
        
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive {
            return 1
        }
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 1 { return 1 }
        
        let count = searchController.isActive ? searchedBusStations.count : busStations.count
        hintLabel.isHidden = !searchController.isActive || count > 0
        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Basic", for: indexPath)
            let busStation = searchController.isActive ? searchedBusStations[indexPath.row] : busStations[indexPath.row]
            cell.textLabel?.text = busStation.name
            return cell
        case 1:
            return tableView.dequeueReusableCell(withIdentifier: "CreateStation", for: indexPath)
        default:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard indexPath.section == 0 else { return }
        
        let busStation = searchController.isActive ? searchedBusStations[indexPath.row] : busStations[indexPath.row]
        
        if selectedBusStations.contains(busStation) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        } else {
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            let busStation = searchController.isActive ? searchedBusStations[indexPath.row] : busStations[indexPath.row]
            selectedBusStations.append(busStation)
            
        } else { // creation new station
            presentAlertForCreateStation(excludedStationNames: BusStation.activeStations.map { $0.name }) { station in
                tableView.deselectRow(at: indexPath, animated: true)
                guard let station = station else { return }
                self.selectedBusStations.append(station)
                BusStation.activeStations.append(station)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let busStation = searchController.isActive ? searchedBusStations[indexPath.row] : busStations[indexPath.row]
            if let index = selectedBusStations.index(of: busStation) {
                selectedBusStations.remove(at: index)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    
    @IBAction func cancelButtonItemDidTap(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func saveButtonItemDidTap(_ sender: UIBarButtonItem) {
        addStationsHandler?(selectedBusStations)
        dismiss(animated: true)
    }
    
}

