-- Table creation

-- Create USERS table
CREATE TABLE USERS (
    USER_ID NUMBER,
    USERNAME VARCHAR2(50),
    PASSWORD_HASH VARCHAR2(100),
    EMAIL VARCHAR2(100),
    FULL_NAME VARCHAR2(100),
    CREATED_AT TIMESTAMP,
    LOGIN_STATUS NUMBER,
    PRIMARY KEY (USER_ID)
);

-- Create EXPENSES table
CREATE TABLE EXPENSES (
    EXPENSE_ID NUMBER,
    USER_ID NUMBER,
    CATEGORY_ID NUMBER,
    AMOUNT NUMBER,
    EXPENSE_DATE DATE,
    NOTES VARCHAR2(200),
    SPENT_AT TIMESTAMP,
    PRIMARY KEY (EXPENSE_ID)
);

-- Create LOGIN_REGISTER table
CREATE TABLE LOGIN_REGISTER (
    ACTIVITY_ID NUMBER,
    USER_ID NUMBER,
    ACTIVITY_TYPE VARCHAR2(10),
    ACTIVITY_TIME TIMESTAMP,
    PRIMARY KEY (ACTIVITY_ID)
);

-- Create CATEGORIES table
CREATE TABLE EXPENSE_CATEGORIES (
    CATEGORY_ID NUMBER,
    NAME VARCHAR2(50),
    DESCRIPTION VARCHAR2(200),
    PRIMARY KEY (CATEGORY_ID)
);

--Create Income table
CREATE TABLE INCOME
   ( INCOME_ID NUMBER, 
	USER_ID NUMBER, 
	AMOUNT NUMBER, 
	NOTES VARCHAR2(200 BYTE), 
	RECEIVED_AT TIMESTAMP (6), 
	 PRIMARY KEY ("INCOME_ID"));

--Create Tracation log table
CREATE TABLE ACTIVITY_LOG
(
    AUDIT_ID NUMBER,
    USER_ID NUMBER,
    TRANS_TYPE VARCHAR2(20 BYTE),
    TRANS_ID NUMBER,
    ACTIVITY VARCHAR2(100 BYTE),
    DATE_TIME TIMESTAMP(6),
    PRIMARY KEY (AUDIT_ID)
);

-- Sequence for user_id
CREATE SEQUENCE user_id_seq;

-- Sequence for expense_id
CREATE SEQUENCE expense_id_seq;

-- Sequence for activity_id
CREATE SEQUENCE activity_id_seq;

-- Sequence for audit_id
CREATE SEQUENCE audit_id_seq;

-- Sequence for income_id
CREATE SEQUENCE income_id_seq;


--Insert values into EXPENSE_CATEGORIES 
INSERT INTO EXPENSE_CATEGORIES (CATEGORY_ID, NAME, DESCRIPTION) VALUES (1, 'Groceries', 'Expenses related to grocery items');
INSERT INTO EXPENSE_CATEGORIES (CATEGORY_ID, NAME, DESCRIPTION) VALUES (2, 'Utilities', 'Expenses related to utility bills');
INSERT INTO EXPENSE_CATEGORIES (CATEGORY_ID, NAME, DESCRIPTION) VALUES (3, 'Transportation', 'Expenses related to transportation costs');
INSERT INTO EXPENSE_CATEGORIES (CATEGORY_ID, NAME, DESCRIPTION) VALUES (4, 'Entertainment', 'Expenses related to entertainment activities');
INSERT INTO EXPENSE_CATEGORIES (CATEGORY_ID, NAME, DESCRIPTION) VALUES (5, 'Healthcare', 'Expenses related to healthcare services');
INSERT INTO EXPENSE_CATEGORIES (CATEGORY_ID, NAME, DESCRIPTION) VALUES (6, 'Dining', 'Expenses related to dining out');
INSERT INTO EXPENSE_CATEGORIES (CATEGORY_ID, NAME, DESCRIPTION) VALUES (7, 'Travel', 'Expenses related to travel expenses');
INSERT INTO EXPENSE_CATEGORIES (CATEGORY_ID, NAME, DESCRIPTION) VALUES (8, 'Shopping', 'Expenses related to shopping purchases');
INSERT INTO EXPENSE_CATEGORIES (CATEGORY_ID, NAME, DESCRIPTION) VALUES (9, 'Education', 'Expenses related to educational expenses');
INSERT INTO EXPENSE_CATEGORIES (CATEGORY_ID, NAME, DESCRIPTION) VALUES (10, 'Miscellaneous', 'Miscellaneous expenses');

--Creating Procedures into packages
--Create User package
create or replace PACKAGE user_pkg AS
    PROCEDURE create_user(
        p_username   IN  VARCHAR2,
        p_password   IN  VARCHAR2,
        p_email      IN  VARCHAR2,
        p_full_name  IN  VARCHAR2
    );

    PROCEDURE authenticate_user(
        p_username   IN  VARCHAR2,
        p_password   IN  VARCHAR2
    );

    PROCEDURE logout_user(
        p_username   IN  VARCHAR2
    );

    PROCEDURE delete_user(
        p_username   IN  VARCHAR2
    );

END user_pkg;

create or replace PACKAGE BODY user_pkg AS

    PROCEDURE create_user(
        p_username   IN  VARCHAR2,
        p_password   IN  VARCHAR2,
        p_email      IN  VARCHAR2,
        p_full_name  IN  VARCHAR2
    )
    IS
        v_user_id users.user_id%TYPE;
    BEGIN
        -- Validate input parameters
        IF p_username IS NULL OR p_password IS NULL OR p_email IS NULL OR p_full_name IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'All parameters must be provided');
        END IF;

        -- Validate email format
        IF NOT REGEXP_LIKE(p_email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$') THEN
            RAISE_APPLICATION_ERROR(-20002, 'Invalid email format.');
        END IF;

        -- Check if username already exists
        BEGIN
            SELECT user_id INTO v_user_id FROM users WHERE username = p_username;
            RAISE_APPLICATION_ERROR(-20002, 'Username already exists');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- Do nothing, continue with user creation
                NULL;
        END;

        -- Insert user record
        INSERT INTO users (user_id, username, password_hash, email, full_name, created_at, login_status)
        VALUES (user_id_seq.NEXTVAL, p_username, DBMS_OBFUSCATION_TOOLKIT.md5(input => UTL_RAW.cast_to_raw(p_password)), p_email, p_full_name, SYSTIMESTAMP, 0);

        COMMIT;

        DBMS_OUTPUT.PUT_LINE('User created successfully');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20003, 'Duplicate email address. User creation failed.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20004, 'An error occurred while creating the user: ' || SQLERRM);
    END create_user;

    PROCEDURE authenticate_user(
        p_username   IN  VARCHAR2,
        p_password   IN  VARCHAR2
    )
    IS
        v_password_hash users.password_hash%TYPE;
    BEGIN
        -- Check if username exists and retrieve the password hash
        SELECT password_hash INTO v_password_hash
        FROM users
        WHERE username = p_username;

        -- Verify password
        IF DBMS_OBFUSCATION_TOOLKIT.md5(input => UTL_RAW.cast_to_raw(p_password)) = v_password_hash THEN
            -- Authentication successful
            UPDATE users
            SET login_status = 1
            WHERE username = p_username;

            -- Log login activity
            INSERT INTO login_register (activity_id, user_id, activity_type, activity_time)
            VALUES (activity_id_seq.NEXTVAL, (SELECT user_id FROM users WHERE username = p_username), 'LOGIN', SYSTIMESTAMP);

            COMMIT; -- Commit the transaction

            DBMS_OUTPUT.PUT_LINE('Authentication successful');
        ELSE
            -- Authentication failed
            DBMS_OUTPUT.PUT_LINE('Authentication failed');
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Username not found
            DBMS_OUTPUT.PUT_LINE('Username not found');
        WHEN OTHERS THEN
            -- An error occurred
            DBMS_OUTPUT.PUT_LINE('An error occurred while authenticating the user');
    END authenticate_user;

    PROCEDURE logout_user(
        p_username   IN  VARCHAR2
    )
    IS
    BEGIN
        -- Update login_status to 0 for the specified user
        UPDATE users
        SET login_status = 0
        WHERE username = p_username;

        -- Log logout activity
        INSERT INTO login_register (activity_id, user_id, activity_type, activity_time)
        VALUES (activity_id_seq.NEXTVAL, (SELECT user_id FROM users WHERE username = p_username), 'LOGOUT', SYSTIMESTAMP);

        -- Commit the transaction
        COMMIT;

        DBMS_OUTPUT.PUT_LINE('User logged out successfully');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('User not found');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('An error occurred while logging out the user: ' || SQLERRM);
    END logout_user;

    PROCEDURE delete_user(
        p_username   IN  VARCHAR2
    )
    IS
        v_user_id       users.user_id%TYPE;
        v_login_status  users.login_status%TYPE;
    BEGIN
        -- Lookup user_id based on username
        SELECT user_id INTO v_user_id
        FROM users
        WHERE username = p_username;

        -- Lookup login status
        SELECT login_status INTO v_login_status
        FROM users
        WHERE user_id = v_user_id;

        -- Check login status
        IF v_login_status != 1 THEN
            RAISE_APPLICATION_ERROR(-20002, 'User must be logged in before adding an expense.');
        END IF;

        -- Delete the user
        DELETE FROM users WHERE username = p_username;

        -- Commit the transaction
        COMMIT;

        DBMS_OUTPUT.PUT_LINE('User deleted successfully');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('User not found');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('An error occurred while deleting the user: ' || SQLERRM);
    END delete_user;

END user_pkg;

--Create Income package
create or replace PACKAGE income_pkg AS
    PROCEDURE add_income(
        p_username       IN  VARCHAR2,
        p_amount         IN  NUMBER,
        p_notes          IN  VARCHAR2 DEFAULT NULL
    );
    PROCEDURE update_last_income_amt(
        p_username  IN  VARCHAR2,
        p_amount    IN  NUMBER
    );
    PROCEDURE get_total_received_amount(
        p_username  IN  VARCHAR2,
        p_total_amount OUT NUMBER
    );
    PROCEDURE get_user_incomes(
        p_username   IN  VARCHAR2,
        p_incomes    OUT SYS_REFCURSOR
    );
END income_pkg;

create or replace PACKAGE BODY income_pkg AS
    PROCEDURE add_income(
        p_username       IN  VARCHAR2,
        p_amount         IN  NUMBER,
        p_notes          IN  VARCHAR2 DEFAULT NULL
    )
    IS
        v_user_id       users.user_id%TYPE;
        v_login_status  users.login_status%TYPE;
    BEGIN
        -- Validate input parameters
        IF p_username IS NULL OR p_amount IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'All parameters must be provided');
        END IF;
        -- Lookup user_id based on username
        SELECT user_id INTO v_user_id
        FROM users
        WHERE username = p_username;

        -- Lookup login status
        SELECT login_status INTO v_login_status
        FROM users
        WHERE user_id = v_user_id;

        -- Check login status
        IF v_login_status != 1 THEN
            RAISE_APPLICATION_ERROR(-20002, 'User must be logged in before adding an expense.');
        END IF;

        -- Insert income record directly without selecting the sequence nextval
        INSERT INTO income (income_id, user_id, amount, notes, received_at)
        VALUES (income_id_seq.NEXTVAL, v_user_id, p_amount, p_notes, systimestamp);
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Income added successfully');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'User not found.');
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20004, 'Duplicate income ID generated.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20005, 'An error occurred while adding the income: ' || SQLERRM);
    END add_income;
    PROCEDURE update_last_income_amt(
        p_username  IN  VARCHAR2,
        p_amount    IN  NUMBER
    )
    IS
        v_user_id         users.user_id%TYPE;
        v_last_income_id income.income_id%TYPE;
        v_login_status  users.login_status%TYPE;
    BEGIN
        -- Validate input parameters
        IF p_username IS NULL OR p_amount IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'All parameters must be provided');
        END IF;
        -- Lookup user_id based on username
        SELECT user_id INTO v_user_id
        FROM users
        WHERE username = p_username;

        -- Lookup login status
        SELECT login_status INTO v_login_status
        FROM users
        WHERE user_id = v_user_id;

        -- Check login status
        IF v_login_status != 1 THEN
            RAISE_APPLICATION_ERROR(-20002, 'User must be logged in before adding an expense.');
        END IF;

        -- Lookup last income_id for the user
        SELECT income_id INTO v_last_income_id
        FROM (
            SELECT income_id
            FROM income
            WHERE user_id = v_user_id
            ORDER BY received_at DESC
        )
        WHERE ROWNUM = 1;
        -- Update income amount
        UPDATE income
        SET amount = p_amount
        WHERE income_id = v_last_income_id;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Amount of last income updated successfully');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'No income found for the user.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20003, 'An error occurred while updating the amount of last income: ' || SQLERRM);
    END update_last_income_amt;

    PROCEDURE get_total_received_amount(
        p_username  IN  VARCHAR2,
        p_total_amount OUT NUMBER
    )
    IS
        v_user_id       users.user_id%TYPE;
        v_login_status  users.login_status%TYPE;
    BEGIN 
        -- Lookup user_id based on username
        SELECT user_id INTO v_user_id
        FROM users
        WHERE username = p_username;

        -- Lookup login status
        SELECT login_status INTO v_login_status
        FROM users
        WHERE user_id = v_user_id;

        -- Check login status
        IF v_login_status != 1 THEN
            RAISE_APPLICATION_ERROR(-20002, 'User must be logged in before adding an expense.');
        END IF;

        SELECT NVL(SUM(amount), 0)
        INTO p_total_amount
        FROM income
        WHERE user_id = (SELECT user_id FROM users WHERE username = p_username);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20004, 'User not found.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20005, 'An error occurred while fetching total received amount: ' || SQLERRM);
    END get_total_received_amount;
    PROCEDURE get_user_incomes(
        p_username   IN  VARCHAR2,
        p_incomes    OUT SYS_REFCURSOR
    )
    IS  
        v_user_id       users.user_id%TYPE;
        v_login_status  users.login_status%TYPE;
    BEGIN
        OPEN p_incomes FOR
            SELECT * FROM income
            WHERE user_id = (SELECT user_id FROM users WHERE username = p_username);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20006, 'User not found.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20007, 'An error occurred while fetching user incomes: ' || SQLERRM);
    END get_user_incomes;
END income_pkg;

--Create Expense Package
create or replace PACKAGE expense_pkg AS
    PROCEDURE add_expense(
        p_username       IN  VARCHAR2,
        p_category_name  IN  VARCHAR2,
        p_amount         IN  NUMBER,
        p_notes          IN  VARCHAR2 DEFAULT NULL
    );

    PROCEDURE update_last_exp_amt(
        p_username  IN  VARCHAR2,
        p_amount    IN  NUMBER
    );

    PROCEDURE update_last_category(
        p_username       IN  VARCHAR2,
        p_category_name  IN  VARCHAR2
    );

    PROCEDURE get_user_expense_by_category(
        p_username       IN  VARCHAR2,
        p_category_name  IN  VARCHAR2,
        p_expense_details OUT SYS_REFCURSOR
    );

    PROCEDURE get_user_expenses(
        p_username   IN  VARCHAR2,
        p_expenses   OUT SYS_REFCURSOR
    );

END expense_pkg;

create or replace PACKAGE BODY expense_pkg AS
    PROCEDURE add_expense(
        p_username       IN  VARCHAR2,
        p_category_name  IN  VARCHAR2,
        p_amount         IN  NUMBER,
        p_notes          IN  VARCHAR2 DEFAULT NULL
    )
    IS
        v_user_id       users.user_id%TYPE;
        v_category_id   expense_categories.category_id%TYPE;
        v_login_status  users.login_status%TYPE;
    BEGIN
        -- Validate input parameters
        IF p_username IS NULL OR p_category_name IS NULL OR p_amount IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'All parameters must be provided');
        END IF;

        -- Lookup user_id based on username
        SELECT user_id INTO v_user_id
        FROM users
        WHERE username = p_username;

        -- Lookup login status
        SELECT login_status INTO v_login_status
        FROM users
        WHERE user_id = v_user_id;

        -- Check login status
        IF v_login_status != 1 THEN
            RAISE_APPLICATION_ERROR(-20002, 'User must be logged in before adding an expense.');
        END IF;

        -- Lookup category_id based on category_name (case-insensitive comparison)
        SELECT category_id INTO v_category_id
        FROM expense_categories
        WHERE UPPER(name) = UPPER(p_category_name);

        -- Insert expense record directly without selecting the sequence nextval
        INSERT INTO expenses (expense_id, user_id, category_id, amount, notes, spent_at)
        VALUES (expense_id_seq.NEXTVAL, v_user_id, v_category_id, p_amount, p_notes, SYSTIMESTAMP);

        COMMIT;

        DBMS_OUTPUT.PUT_LINE('Expense added successfully');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'User or category not found.');
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20004, 'Duplicate expense ID generated.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20005, 'An error occurred while adding the expense: ' || SQLERRM);
    END add_expense;

    PROCEDURE update_last_exp_amt(
        p_username  IN  VARCHAR2,
        p_amount    IN  NUMBER
    )
    IS
        v_user_id         users.user_id%TYPE;
        v_last_expense_id expenses.expense_id%TYPE;
    BEGIN
        -- Validate input parameters
        IF p_username IS NULL OR p_amount IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'All parameters must be provided');
        END IF;

        -- Lookup user_id based on username
        SELECT user_id INTO v_user_id
        FROM users
        WHERE username = p_username;

        -- Lookup last expense_id for the user
        SELECT expense_id INTO v_last_expense_id
        FROM (
            SELECT expense_id
            FROM expenses
            WHERE user_id = v_user_id
            ORDER BY spent_at DESC
        )
        WHERE ROWNUM = 1;

        -- Update expense amount
        UPDATE expenses
        SET amount = p_amount
        WHERE expense_id = v_last_expense_id;

        COMMIT;

        DBMS_OUTPUT.PUT_LINE('Amount of last expense updated successfully');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'No expense found for the user.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20003, 'An error occurred while updating the amount of last expense: ' || SQLERRM);
    END update_last_exp_amt;

    PROCEDURE update_last_category(
        p_username       IN  VARCHAR2,
        p_category_name  IN  VARCHAR2
    )
    IS
        v_user_id         users.user_id%TYPE;
        v_last_expense_id expenses.expense_id%TYPE;
        v_category_id     expense_categories.category_id%TYPE;
    BEGIN
        -- Validate input parameters
        IF p_username IS NULL OR p_category_name IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'All parameters must be provided');
        END IF;

        -- Lookup user_id based on username
        SELECT user_id INTO v_user_id
        FROM users
        WHERE username = p_username;

        -- Lookup last expense_id for the user
        SELECT expense_id INTO v_last_expense_id
        FROM (
            SELECT expense_id
            FROM expenses
            WHERE user_id = v_user_id
            ORDER BY spent_at DESC
        )
        WHERE ROWNUM = 1;

        -- Lookup category_id based on category_name (case-insensitive comparison)
        SELECT category_id INTO v_category_id
        FROM expense_categories
        WHERE UPPER(name) = UPPER(p_category_name);

        -- Update expense category
        UPDATE expenses
        SET category_id = v_category_id
        WHERE expense_id = v_last_expense_id;

        COMMIT;

        DBMS_OUTPUT.PUT_LINE('Category of last expense updated successfully');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'No expense found for the user.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20003, 'An error occurred while updating the category of last expense: ' || SQLERRM);
    END update_last_category;

    PROCEDURE get_user_expense_by_category(
        p_username       IN  VARCHAR2,
        p_category_name  IN  VARCHAR2,
        p_expense_details OUT SYS_REFCURSOR
    )
    IS
        v_user_id users.user_id%TYPE;
        v_login_status users.login_status%TYPE;
    BEGIN
        -- Check if the user exists and is logged in
        SELECT user_id, login_status INTO v_user_id, v_login_status
        FROM users
        WHERE username = p_username;

        IF v_login_status = 1 THEN
            -- Open a cursor to fetch expense details for the given username and category name
            OPEN p_expense_details FOR
                SELECT e.expense_id, e.amount, e.notes,  e.spent_at
                FROM expenses e
                JOIN expense_categories c ON e.category_id = c.category_id
                WHERE e.user_id = v_user_id
                AND c.name = p_category_name;

            -- Check if any rows are fetched, if not, raise an exception
            IF NOT p_expense_details%FOUND THEN
                RAISE_APPLICATION_ERROR(-20002, 'No expenses found for the provided category name.');
            END IF;
        ELSE
            -- If the user is not logged in, raise an exception
            RAISE_APPLICATION_ERROR(-20001, 'User is not logged in.');
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- If the user does not exist or category name is not found, raise an exception
            RAISE_APPLICATION_ERROR(-20003, 'User or category name not found.');
    END get_user_expense_by_category;

    PROCEDURE get_user_expenses(
        p_username   IN  VARCHAR2,
        p_expenses   OUT SYS_REFCURSOR
    )
    IS
        v_user_id users.user_id%TYPE;
        v_login_status users.login_status%TYPE;
    BEGIN
        -- Check if the user exists
        SELECT user_id, login_status INTO v_user_id, v_login_status
        FROM users
        WHERE username = p_username;

        -- Check if the user is logged in
        IF v_login_status = 1 THEN
            -- Open a cursor to fetch expenses for the given username
            OPEN p_expenses FOR
                SELECT c.name AS category_name, e.amount, e.notes, e.spent_at
                FROM expenses e
                JOIN expense_categories c ON e.category_id = c.category_id
                WHERE e.user_id = v_user_id;

        ELSE
            -- If the user is not logged in, raise an exception
            RAISE_APPLICATION_ERROR(-20001, 'User is not logged in.');
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- If the user does not exist, raise an exception
            RAISE_APPLICATION_ERROR(-20002, 'User not found.');
    END get_user_expenses;
END expense_pkg;

--Triggers
--User Triggers
create or replace TRIGGER users_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW
DECLARE
    v_action VARCHAR2(20);
BEGIN
    IF INSERTING THEN
        v_action := 'INSERT';
    ELSIF UPDATING THEN
        v_action := 'UPDATE';
    ELSE
        v_action := 'DELETE';
    END IF;

    INSERT INTO activity_log (audit_id, user_id, trans_type, trans_id, activity, date_time)
    VALUES (audit_id_seq.NEXTVAL, :NEW.user_id, v_action, NULL, 'Action on USERS table', SYSTIMESTAMP);
END users_audit_trigger;

--Income Trigger
create or replace TRIGGER income_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON income
FOR EACH ROW
DECLARE
    v_action VARCHAR2(20);
BEGIN
    IF INSERTING THEN
        v_action := 'INSERT';
    ELSIF UPDATING THEN
        v_action := 'UPDATE';
    ELSE
        v_action := 'DELETE';
    END IF;

    INSERT INTO activity_log (audit_id, user_id, trans_type, trans_id, activity, date_time)
    VALUES (audit_id_seq.NEXTVAL, :NEW.user_id, v_action, :NEW.income_id, 'Action on INCOME table', SYSTIMESTAMP);
END income_audit_trigger;

--Expense Triggers
create or replace TRIGGER expenses_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON expenses
FOR EACH ROW
DECLARE
    v_action VARCHAR2(20);
BEGIN
    IF INSERTING THEN
        v_action := 'INSERT';
    ELSIF UPDATING THEN
        v_action := 'UPDATE';
    ELSE
        v_action := 'DELETE';
    END IF;

    INSERT INTO activity_log (audit_id, user_id, trans_type, trans_id, activity, date_time)
    VALUES (audit_id_seq.NEXTVAL, :NEW.user_id, v_action, :NEW.expense_id, 'Action on EXPENSES table', SYSTIMESTAMP);
END expenses_audit_trigger;
