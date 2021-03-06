import UIKit

extension ChooseAppViewController {
    private struct Constant {
        static let appCellIdentifier = "AppCellIdentifier"
        static let buildsSegueIdentifier = "BuildsStoryboardSegue"

        struct Section {
            static let app = 0
        }
    }
}

class ChooseAppViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView?
    
    private var cellForRowCallbacks: [((Int) -> Bool, (UITableView, IndexPath) -> UITableViewCell)] = []
    private var didSelectCellCallbacks: [((Int) -> Bool, (UITableView, IndexPath) -> Void)] = []
    private var numberOfRowsCallbacks: [((Int) -> Bool, () -> Int)] = []
    
    var apps: [AppResponse]? {
        didSet {
            tableView?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Buddy.service.getApps { result in
            switch result {
            case .success(let response):
                self.apps = response
            case .failure(let error):
                print("Error: \(error)")
            }
        }
        
        initializeCallbacks()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let index = (sender as? UITableViewCell).flatMap({ tableView?.indexPath(for: $0) }),
            let buildsViewController = segue.destination as? BuildsViewController else {
            return
        }
        let app = apps?[index.row]
        buildsViewController.app = app
    }
    
    private func initializeCallbacks() {
        cellForRowCallbacks = [({ section in return section == Constant.Section.app }, buildAppCell)]
        numberOfRowsCallbacks = [({ section in return section == Constant.Section.app }, numberOfApps)]
        didSelectCellCallbacks = [({ section in return section == Constant.Section.app }, didSelectApp)]
    }
}

extension ChooseAppViewController {
    private func buildAppCell(_ tableView: UITableView, indexPath: IndexPath) -> AppTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constant.appCellIdentifier) as? AppTableViewCell
        cell?.app = apps?[indexPath.row]
        return cell ?? AppTableViewCell()
    }
    
    private func numberOfApps() -> Int {
        return apps?.count ?? 0
    }
    
    private func didSelectApp(_tableView: UITableView, indexPath: IndexPath) {
        let cell = tableView?.cellForRow(at: indexPath)
        performSegue(withIdentifier: Constant.buildsSegueIdentifier, sender: cell)
    }
}

extension ChooseAppViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsCallbacks.first(where: { $0.0(section) })?.1() ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cellForRowCallbacks.first(where: { $0.0(indexPath.section) })?.1(tableView, indexPath) ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        didSelectCellCallbacks.first(where: { $0.0(indexPath.section) })?.1(tableView, indexPath)
    }
}
