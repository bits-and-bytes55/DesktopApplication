# TODO: Dynamically Populate Engineer Dropdowns in Well Tab Content

## Steps to Complete:
- [ ] Import EngineerController in well_tab_content.dart
- [ ] Get instance of EngineerController in GeneralSection
- [ ] Remove hardcoded engineerOptions and engineer2Options lists
- [ ] Make selectedEngineer and selectedEngineer2 nullable (String?)
- [ ] In initState, ensure engineers are fetched if not already done
- [ ] Wrap dropdowns in Obx for reactivity to engineerController.engineers
- [ ] Dynamically generate options from engineerController.engineers.map((e) => "${e.firstName} ${e.lastName}").toList()
- [ ] Update onChanged to set both selected value and fieldControllers text
- [ ] Add hints like "Select Engineer" for better UX
- [ ] Handle both "Engineer" and "Engineer 2" dropdowns similarly
