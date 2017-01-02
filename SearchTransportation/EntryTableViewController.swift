//
//  EntryTableViewController.swift
//  SearchTransportation
//
//  Created by Jonny on 12/31/16.
//  Copyright © 2016 Jonny. All rights reserved.
//

import UIKit

class EntryTableViewController: UITableViewController {
    
    private enum SegueIdentifier: String {
        case showSignUpViewController
        case showStationTableViewController
        case showRouteTableViewController
        case showSelectStartStationTableViewController
    }
    
    private enum Feature: String {
        case manageStations = "Manage Stations"
        case manageRoutes = "Manage Routes"
        case searchRoutes = "Search Routes"
        case accountSettings = "Modify Account Infos"
        case signOut = "Sign Out and Delete Account"
    }
    
    var account: Account?
    
    private let featuresArray: [[Feature]] = [[.manageStations, .manageRoutes], [.searchRoutes], [.accountSettings, .signOut]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.cellLayoutMarginsFollowReadableWidth = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let signUpVC = segue.destination as? SignUpViewController {
            signUpVC.accountToModify = account
            signUpVC.newAccountRegisterHandler = { [weak self] newAccount in
                self?.account = newAccount
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return featuresArray.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return featuresArray[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Basic", for: indexPath)
        let feature = featuresArray[indexPath.section][indexPath.row]
        
        cell.textLabel?.text = feature.rawValue
        
        if feature == .signOut {
            cell.textLabel?.textColor = .red
            cell.accessoryType = .none
        } else {
            cell.textLabel?.textColor = .black
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch featuresArray[indexPath.section][indexPath.row] {
        case .manageStations:
            performSegue(withIdentifier: SegueIdentifier.showStationTableViewController.rawValue, sender: nil)
        case .manageRoutes:
            performSegue(withIdentifier: SegueIdentifier.showRouteTableViewController.rawValue, sender: nil)
        case .searchRoutes:
            performSegue(withIdentifier: SegueIdentifier.showSelectStartStationTableViewController.rawValue, sender: nil)
        case .accountSettings:
            performSegue(withIdentifier: SegueIdentifier.showSignUpViewController.rawValue, sender: account)
        case .signOut:
            if let account = account {
                try? AccountManager.shared.delete(account)
            }
            _ = navigationController?.popViewController(animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == featuresArray.count - 1 else { return nil }
        return "Copyright © 2017 Junyu Kuang. All rights reserved."
    }
    
}
