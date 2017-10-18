//
//  FormTableViewController.swift
//  ShopClothes
//
//  Created by Sahand on 9/28/17.
//  Copyright © 2017 Sahand. All rights reserved.
//

import UIKit

typealias FormValues = [String: Any]

class FormTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, KeyboardAppearanceDelegate {
    
    var form = Form(sections: []) {
        didSet {
            tableView.reloadData()
        }
    }
    var formValues: FormValues = [:]
    
    let tableView = UITableView(frame: .zero, style: .grouped)
    
    var keyboardObserver: NSObjectProtocol?
    
    var makesFirstRowFirstResponder = true

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.size.equalTo(view.safeAreaLayoutGuide)
            make.center.equalTo(view.safeAreaLayoutGuide)
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        tableView.register(FormTextTableViewCell.self, forCellReuseIdentifier: "FormTextTableViewCell")
        tableView.register(FormButtonTableViewCell.self, forCellReuseIdentifier: "FormButtonTableViewCell")
        tableView.keyboardDismissMode = .interactive
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        listenForKeyboardAppearance()
        
        if makesFirstRowFirstResponder {
            tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.becomeFirstResponder()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopListeningForKeyboardAppearance()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return form.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return form.sections[section].fields.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return form.sections[section].header
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return form.sections[section].footer
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        let field = form.sections[indexPath.section].fields[indexPath.row]
        switch field {
        case .text(let description):
            let textCell = tableView.dequeueReusableCell(withIdentifier: "FormTextTableViewCell", for: indexPath) as! FormTextTableViewCell
            cell = textCell
            textCell.formTableViewController = self
            textCell.set(for: description, value: formValues[description.tag])
            
            description.configureCell?(textCell)
            description.validateCell?(textCell, formValues)
        case .button(let description):
            let buttonCell = tableView.dequeueReusableCell(withIdentifier: "FormButtonTableViewCell", for: indexPath) as! FormButtonTableViewCell
            cell = buttonCell
            buttonCell.formTableViewController = self
            buttonCell.set(for: description)
            description.configureCell?(buttonCell)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        
        if cell.canBecomeFirstResponder {
            cell.becomeFirstResponder()
        }
    }
    
    func updateValueFrom(_ cell: UITableViewCell, to value: Any?) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            fatalError("Could not get indexpath of cell")
        }
        
        let tag = form.sections[indexPath.section].fields[indexPath.row].description.tag
        formValues[tag] = value
        
        validateIfNeededFrom(cell)
        formDidUpdate()
    }
    
    func validateIfNeededFrom(_ cell: UITableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            fatalError("Could not get indexpath of cell")
        }
        
        let field = form.sections[indexPath.section].fields[indexPath.row]
        switch field {
        case .text(let description):
            guard let textCell = cell as? FormTextTableViewCell else {
                fatalError("Not a text cell")
            }
            
            description.validateCell?(textCell, formValues)
        case .button(_):
            break
        }
    }
    
    open func formDidUpdate() {}
    
    func canGoToNextFrom(_ cell: UITableViewCell) -> UIView? {
        guard let indexPathOfCell = tableView.indexPath(for: cell) else {
            return nil
        }

        if let nextCellInSection = tableView.cellForRow(at: IndexPath(row: indexPathOfCell.row + 1, section: indexPathOfCell.section)) {
            return nextCellInSection
        }

        if let nextCellInTableView = tableView.cellForRow(at: IndexPath(row: 0, section: indexPathOfCell.section + 1)) {
            return nextCellInTableView
        }

        return nil
    }
    
    func keyboardWillHide(toEndHeight height: CGFloat) {
        tableView.contentInset = UIEdgeInsets.zero
    }
    
    func keyboardWillShow(toEndHeight height: CGFloat) {
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: height, right: 0)
    }

}

extension FormTableViewController {
    var allFieldsAreValid: Bool {
        let allFields = form.sections.flatMap { return $0.fields }
        let invalidFields = allFields.filter { field in
            switch field {
            case .text(let description):
                return description.isValid(formValues) == false
            case .button(_):
                return true
            }
            }
        return invalidFields.isEmpty
    }
}
