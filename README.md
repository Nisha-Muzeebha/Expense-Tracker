# Expense-Tracker
![ER Daigram](https://github.com/Nisha-Muzeebha/Expense-Tracker/assets/133625196/d2ed9d18-509d-478c-bb12-43dd05f09d91)

### What it's capable of?​
- User Management: Facilitating user creation, authentication, and logout functionalities.​
- Expense Handling: Offering features to add, update, and retrieve expenses.​
- Income Management: Providing functions for income addition, updating, and retrieval.​

### Verification and Access Control​
- Validate User Credentials: Check for a valid email and a unique username at the time of user creation.​
- Authentication: The password undergoes hashing before storage, and during login, we compare the hashed values for verification.​
- Access Control: Restrict access to sensitive operations such as adding, updating, and retrieving data to authenticated users only.​

- **Logging user activities​:** used Triggers,​ Activity log table keeps track of the modifications made in other tables.​
- **Deleting a user​:** used cascading,​ Automatically removes related data when a user is deleted.​
- **Procedure Organization​:** used packages, To organize stored procedures belongs to related tables, enhancing modularity and maintainability in our application.
- **Data Retrivel:**  used Cursors,​ Implemented cursors to efficiently retrieve and process expense and income data.​

​


​

​

​
