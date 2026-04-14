# TODO: Remove Update Company Details Logic from Company Controller

## Steps to Complete:
- [x] Modify `saveCompanyDetails` method to add check: if company already exists, show error and prevent saving
- [x] Remove conditional logic for add vs update, always call addCompanyDetails if no company exists
