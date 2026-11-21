-- CS 202 | University Library Management System
-- PostgreSQL. Run this file in an empty database using the Query Tool or psql.
-- The 62 tables follow the revised relational schema in Library(3).docx.
-- Data types, local checks, and composite references enforce structural integrity.

BEGIN;

-- Shared tables

CREATE TABLE university_department (
    department_id integer PRIMARY KEY CHECK (department_id > 0),
    name text NOT NULL,
    office_location text NOT NULL
);

CREATE TABLE library_branch (
    branch_id integer PRIMARY KEY CHECK (branch_id > 0),
    name text NOT NULL,
    address text NOT NULL,
    phone text NOT NULL
);

CREATE TABLE organization (
    organization_id integer PRIMARY KEY CHECK (organization_id > 0),
    name text NOT NULL,
    email text NOT NULL,
    phone text NOT NULL,
    address text NOT NULL,
    website text NOT NULL,
    is_publisher boolean NOT NULL,
    is_supplier boolean NOT NULL,
    is_digital_provider boolean NOT NULL,
    CONSTRAINT organization_has_role
        CHECK (is_publisher OR is_supplier OR is_digital_provider)
);

-- Catalog and item hierarchy

CREATE TABLE book_series (
    series_id integer PRIMARY KEY CHECK (series_id > 0),
    name text NOT NULL,
    description text NOT NULL
);

CREATE TABLE author (
    author_id integer PRIMARY KEY CHECK (author_id > 0),
    name text NOT NULL,
    biography text NOT NULL
);

CREATE TABLE category (
    category_id integer PRIMARY KEY CHECK (category_id > 0),
    name text NOT NULL,
    description text NOT NULL
);

CREATE TABLE language (
    language_code varchar(12) PRIMARY KEY,
    name text NOT NULL
);

CREATE TABLE subject (
    subject_id integer PRIMARY KEY CHECK (subject_id > 0),
    name text NOT NULL,
    description text NOT NULL
);

CREATE TABLE item (
    item_id integer PRIMARY KEY CHECK (item_id > 0),
    title text NOT NULL,
    description text NOT NULL,
    item_type text NOT NULL,
    CHECK (item_type IN ('Book', 'Periodical', 'Thesis', 'Media'))
);

CREATE TABLE book (
    item_id integer PRIMARY KEY REFERENCES item (item_id),
    series_id integer REFERENCES book_series (series_id)
);

CREATE TABLE periodical (
    item_id integer PRIMARY KEY REFERENCES item (item_id),
    issn text NOT NULL,
    frequency text NOT NULL
);

CREATE TABLE thesis (
    item_id integer PRIMARY KEY REFERENCES item (item_id),
    degree text NOT NULL,
    submission_year integer NOT NULL CHECK (submission_year > 0),
    author_name text NOT NULL,
    department_id integer NOT NULL REFERENCES university_department (department_id)
);

CREATE TABLE media (
    item_id integer PRIMARY KEY REFERENCES item (item_id),
    media_type text NOT NULL,
    duration_minutes integer NOT NULL CHECK (duration_minutes > 0),
    format text NOT NULL
);

CREATE TABLE periodical_issue (
    periodical_item_id integer NOT NULL REFERENCES periodical (item_id),
    issue_number integer NOT NULL CHECK (issue_number > 0),
    volume_number integer NOT NULL CHECK (volume_number > 0),
    publication_date date NOT NULL,
    PRIMARY KEY (periodical_item_id, issue_number)
);

CREATE TABLE book_edition (
    edition_id integer PRIMARY KEY CHECK (edition_id > 0),
    isbn text,
    edition_number integer NOT NULL CHECK (edition_number > 0),
    publication_year integer NOT NULL CHECK (publication_year > 0),
    item_id integer NOT NULL REFERENCES book (item_id),
    organization_id integer NOT NULL REFERENCES organization (organization_id),
    UNIQUE (isbn),
    UNIQUE (edition_id, item_id)
);

CREATE TABLE writes (
    author_id integer NOT NULL REFERENCES author (author_id),
    item_id integer NOT NULL REFERENCES book (item_id),
    PRIMARY KEY (author_id, item_id)
);

CREATE TABLE classifies (
    category_id integer NOT NULL REFERENCES category (category_id),
    item_id integer NOT NULL REFERENCES book (item_id),
    PRIMARY KEY (category_id, item_id)
);

CREATE TABLE uses_language (
    language_code varchar(12) NOT NULL REFERENCES language (language_code),
    edition_id integer NOT NULL REFERENCES book_edition (edition_id),
    PRIMARY KEY (language_code, edition_id)
);

CREATE TABLE describes_subject (
    subject_id integer NOT NULL REFERENCES subject (subject_id),
    item_id integer NOT NULL REFERENCES item (item_id),
    PRIMARY KEY (subject_id, item_id)
);

-- Members

CREATE TABLE member (
    member_id integer PRIMARY KEY CHECK (member_id > 0),
    name text NOT NULL,
    email text NOT NULL,
    phone text NOT NULL,
    registration_date date NOT NULL
);

CREATE TABLE student_member (
    member_id integer PRIMARY KEY REFERENCES member (member_id),
    student_number text NOT NULL,
    study_level text NOT NULL,
    department_id integer NOT NULL REFERENCES university_department (department_id),
    UNIQUE (student_number)
);

CREATE TABLE staff_member (
    member_id integer PRIMARY KEY REFERENCES member (member_id),
    employee_number text NOT NULL,
    job_title text NOT NULL,
    department_id integer NOT NULL REFERENCES university_department (department_id),
    UNIQUE (employee_number)
);

CREATE TABLE membership (
    membership_id integer PRIMARY KEY CHECK (membership_id > 0),
    start_date date NOT NULL,
    end_date date NOT NULL,
    status text NOT NULL,
    card_number text NOT NULL,
    card_issue_date date NOT NULL,
    card_expiry_date date NOT NULL,
    member_id integer NOT NULL REFERENCES member (member_id),
    UNIQUE (card_number),
    CHECK (end_date >= start_date),
    CHECK (card_expiry_date >= card_issue_date)
);

CREATE TABLE notification (
    notification_id integer PRIMARY KEY CHECK (notification_id > 0),
    message text NOT NULL,
    created_at timestamp NOT NULL,
    sent_at timestamp,
    is_read boolean NOT NULL,
    member_id integer NOT NULL REFERENCES member (member_id),
    CHECK (sent_at >= created_at)
);

CREATE TABLE librarian (
    librarian_id integer PRIMARY KEY CHECK (librarian_id > 0),
    name text NOT NULL,
    email text NOT NULL,
    hire_date date NOT NULL,
    branch_id integer NOT NULL REFERENCES library_branch (branch_id),
    UNIQUE (librarian_id, branch_id)
);

-- Spaces and equipment

CREATE TABLE floor (
    floor_id integer PRIMARY KEY CHECK (floor_id > 0),
    floor_number integer NOT NULL,
    description text NOT NULL,
    branch_id integer NOT NULL REFERENCES library_branch (branch_id)
);

CREATE TABLE shelf (
    shelf_id integer PRIMARY KEY CHECK (shelf_id > 0),
    label text NOT NULL,
    capacity integer NOT NULL CHECK (capacity > 0),
    floor_id integer NOT NULL REFERENCES floor (floor_id)
);

CREATE TABLE study_room (
    room_id integer PRIMARY KEY CHECK (room_id > 0),
    name text NOT NULL,
    capacity integer NOT NULL CHECK (capacity > 0),
    description text NOT NULL,
    floor_id integer NOT NULL REFERENCES floor (floor_id)
);

CREATE TABLE study_seat (
    seat_id integer PRIMARY KEY CHECK (seat_id > 0),
    seat_label text NOT NULL,
    has_power_outlet boolean NOT NULL,
    floor_id integer NOT NULL REFERENCES floor (floor_id)
);

CREATE TABLE equipment (
    equipment_id integer PRIMARY KEY CHECK (equipment_id > 0),
    name text NOT NULL,
    equipment_type text NOT NULL,
    serial_number text NOT NULL,
    condition text NOT NULL,
    branch_id integer NOT NULL REFERENCES library_branch (branch_id)
);

CREATE TABLE room_booking (
    booking_id integer PRIMARY KEY CHECK (booking_id > 0),
    booking_date date NOT NULL,
    start_time timestamp NOT NULL,
    end_time timestamp NOT NULL,
    status text NOT NULL,
    member_id integer NOT NULL REFERENCES member (member_id),
    room_id integer NOT NULL REFERENCES study_room (room_id),
    CHECK (end_time > start_time)
);

CREATE TABLE maintenance_request (
    maintenance_id integer PRIMARY KEY CHECK (maintenance_id > 0),
    request_date date NOT NULL,
    description text NOT NULL,
    status text NOT NULL,
    completion_date date,
    room_id integer REFERENCES study_room (room_id),
    equipment_id integer REFERENCES equipment (equipment_id),
    librarian_id integer NOT NULL REFERENCES librarian (librarian_id),
    CHECK ((room_id IS NULL) <> (equipment_id IS NULL)),
    CHECK (completion_date >= request_date)
);

-- Acquisitions

CREATE TABLE purchase_request (
    request_id integer PRIMARY KEY CHECK (request_id > 0),
    request_date date NOT NULL,
    requested_quantity integer NOT NULL CHECK (requested_quantity > 0),
    reason text NOT NULL,
    status text NOT NULL,
    member_id integer NOT NULL REFERENCES member (member_id),
    edition_id integer NOT NULL REFERENCES book_edition (edition_id)
);

CREATE TABLE purchase_order (
    order_id integer PRIMARY KEY CHECK (order_id > 0),
    order_date date NOT NULL,
    expected_delivery_date date NOT NULL,
    status text NOT NULL,
    organization_id integer NOT NULL REFERENCES organization (organization_id),
    branch_id integer NOT NULL REFERENCES library_branch (branch_id)
);

CREATE TABLE purchase_order_item (
    order_id integer NOT NULL REFERENCES purchase_order (order_id),
    item_number integer NOT NULL CHECK (item_number > 0),
    quantity integer NOT NULL CHECK (quantity > 0),
    unit_price numeric(12, 2) NOT NULL CHECK (unit_price >= 0),
    edition_id integer NOT NULL REFERENCES book_edition (edition_id),
    PRIMARY KEY (order_id, item_number),
    UNIQUE (order_id, item_number, edition_id)
);

CREATE TABLE delivery (
    delivery_id integer PRIMARY KEY CHECK (delivery_id > 0),
    delivery_date date NOT NULL,
    tracking_number text NOT NULL,
    notes text NOT NULL,
    order_id integer NOT NULL REFERENCES purchase_order (order_id),
    UNIQUE (delivery_id, order_id)
);

CREATE TABLE receives_order_item (
    delivery_id integer NOT NULL REFERENCES delivery (delivery_id),
    order_id integer NOT NULL,
    order_item_number integer NOT NULL CHECK (order_item_number > 0),
    received_quantity integer NOT NULL CHECK (received_quantity > 0),
    PRIMARY KEY (delivery_id, order_id, order_item_number),
    FOREIGN KEY (delivery_id, order_id) REFERENCES delivery (delivery_id, order_id),
    FOREIGN KEY (order_id, order_item_number) REFERENCES purchase_order_item (order_id, item_number)
);

CREATE TABLE invoice (
    invoice_id integer PRIMARY KEY CHECK (invoice_id > 0),
    invoice_number text NOT NULL,
    invoice_date date NOT NULL,
    total_amount numeric(12, 2) NOT NULL CHECK (total_amount >= 0),
    due_date date NOT NULL,
    order_id integer NOT NULL REFERENCES purchase_order (order_id)
);

CREATE TABLE donor (
    donor_id integer PRIMARY KEY CHECK (donor_id > 0),
    name text NOT NULL,
    donor_type text NOT NULL,
    email text NOT NULL,
    phone text NOT NULL
);

CREATE TABLE donation (
    donation_id integer PRIMARY KEY CHECK (donation_id > 0),
    donation_date date NOT NULL,
    notes text NOT NULL,
    donor_id integer NOT NULL REFERENCES donor (donor_id),
    branch_id integer NOT NULL REFERENCES library_branch (branch_id)
);

CREATE TABLE physical_copy (
    copy_id integer PRIMARY KEY CHECK (copy_id > 0),
    barcode text NOT NULL,
    acquisition_date date NOT NULL,
    condition text NOT NULL,
    edition_id integer,
    shelf_id integer REFERENCES shelf (shelf_id),
    donation_id integer REFERENCES donation (donation_id),
    purchase_order_id integer,
    purchase_item_number integer,
    branch_id integer NOT NULL REFERENCES library_branch (branch_id),
    item_id integer NOT NULL REFERENCES item (item_id),
    periodical_item_id integer,
    issue_number integer,
    UNIQUE (barcode),
    FOREIGN KEY (edition_id, item_id) REFERENCES book_edition (edition_id, item_id),
    FOREIGN KEY (periodical_item_id, issue_number)
        REFERENCES periodical_issue (periodical_item_id, issue_number) MATCH FULL,
    FOREIGN KEY (purchase_order_id, purchase_item_number)
        REFERENCES purchase_order_item (order_id, item_number) MATCH FULL,
    FOREIGN KEY (purchase_order_id, purchase_item_number, edition_id)
        REFERENCES purchase_order_item (order_id, item_number, edition_id),
    CHECK (periodical_item_id IS NULL OR periodical_item_id = item_id),
    CHECK (edition_id IS NULL OR issue_number IS NULL),
    CHECK (purchase_order_id IS NULL OR (donation_id IS NULL AND edition_id IS NOT NULL))
);

-- Loans and incidents

CREATE TABLE loan_policy (
    policy_id integer PRIMARY KEY CHECK (policy_id > 0),
    name text NOT NULL,
    member_category text NOT NULL,
    item_category text NOT NULL,
    max_loan_days integer NOT NULL CHECK (max_loan_days > 0),
    max_renewals integer NOT NULL CHECK (max_renewals >= 0),
    daily_fine numeric(12, 2) NOT NULL CHECK (daily_fine >= 0),
    effective_from date NOT NULL,
    effective_to date NOT NULL,
    CHECK (effective_to >= effective_from)
);

CREATE TABLE loan (
    loan_id integer PRIMARY KEY CHECK (loan_id > 0),
    borrow_date date NOT NULL,
    due_date date NOT NULL,
    return_date date,
    loan_status text NOT NULL,
    member_id integer NOT NULL REFERENCES member (member_id),
    copy_id integer REFERENCES physical_copy (copy_id),
    librarian_id integer NOT NULL REFERENCES librarian (librarian_id),
    equipment_id integer REFERENCES equipment (equipment_id),
    policy_id integer NOT NULL REFERENCES loan_policy (policy_id),
    UNIQUE (loan_id, member_id),
    CHECK ((copy_id IS NULL) <> (equipment_id IS NULL)),
    CHECK (due_date >= borrow_date),
    CHECK (return_date >= borrow_date)
);

CREATE TABLE loan_renewal (
    renewal_id integer PRIMARY KEY CHECK (renewal_id > 0),
    renewal_date date NOT NULL,
    previous_due_date date NOT NULL,
    new_due_date date NOT NULL,
    loan_id integer NOT NULL REFERENCES loan (loan_id),
    CHECK (new_due_date > previous_due_date)
);

CREATE TABLE book_reservation (
    reservation_id integer PRIMARY KEY CHECK (reservation_id > 0),
    request_date date NOT NULL,
    expiry_date date NOT NULL,
    status text NOT NULL,
    member_id integer NOT NULL REFERENCES member (member_id),
    edition_id integer NOT NULL REFERENCES book_edition (edition_id),
    CHECK (expiry_date >= request_date)
);

CREATE TABLE fine (
    fine_id integer PRIMARY KEY CHECK (fine_id > 0),
    amount numeric(12, 2) NOT NULL CHECK (amount >= 0),
    reason text NOT NULL,
    issue_date date NOT NULL,
    member_id integer NOT NULL REFERENCES member (member_id),
    loan_id integer NOT NULL,
    FOREIGN KEY (loan_id, member_id) REFERENCES loan (loan_id, member_id)
);

CREATE TABLE payment (
    payment_id integer PRIMARY KEY CHECK (payment_id > 0),
    amount numeric(12, 2) NOT NULL CHECK (amount >= 0),
    payment_date date NOT NULL,
    payment_method text NOT NULL,
    fine_id integer NOT NULL REFERENCES fine (fine_id)
);

CREATE TABLE incident_report (
    report_id integer PRIMARY KEY CHECK (report_id > 0),
    report_type text NOT NULL,
    report_date date NOT NULL,
    description text NOT NULL,
    severity text,
    resolution_status text NOT NULL,
    member_id integer REFERENCES member (member_id),
    copy_id integer NOT NULL REFERENCES physical_copy (copy_id),
    librarian_id integer REFERENCES librarian (librarian_id),
    CONSTRAINT incident_report_type_check
        CHECK (report_type IN ('Lost', 'Damage')),
    CONSTRAINT incident_report_required_fields
        CHECK (
            (report_type = 'Lost' AND member_id IS NOT NULL)
            OR
            (report_type = 'Damage' AND librarian_id IS NOT NULL AND severity IS NOT NULL)
        )
);

-- Inventory and transfers

CREATE TABLE inventory_check (
    check_id integer PRIMARY KEY CHECK (check_id > 0),
    start_date date NOT NULL,
    end_date date NOT NULL,
    notes text NOT NULL,
    branch_id integer NOT NULL REFERENCES library_branch (branch_id),
    CHECK (end_date >= start_date)
);

CREATE TABLE inventory_check_item (
    check_id integer NOT NULL REFERENCES inventory_check (check_id),
    item_number integer NOT NULL CHECK (item_number > 0),
    checked_at timestamp NOT NULL,
    result text NOT NULL,
    notes text NOT NULL,
    copy_id integer NOT NULL REFERENCES physical_copy (copy_id),
    PRIMARY KEY (check_id, item_number),
    UNIQUE (check_id, copy_id)
);

CREATE TABLE copy_transfer (
    transfer_id integer PRIMARY KEY CHECK (transfer_id > 0),
    request_date date NOT NULL,
    dispatch_date date,
    arrival_date date,
    status text NOT NULL,
    copy_id integer NOT NULL REFERENCES physical_copy (copy_id),
    source_branch_id integer NOT NULL REFERENCES library_branch (branch_id),
    destination_branch_id integer NOT NULL REFERENCES library_branch (branch_id),
    CHECK (source_branch_id <> destination_branch_id),
    CHECK (dispatch_date >= request_date),
    CHECK (arrival_date IS NULL OR (dispatch_date IS NOT NULL AND arrival_date >= dispatch_date))
);

-- Events and digital services

CREATE TABLE library_event (
    event_id integer PRIMARY KEY CHECK (event_id > 0),
    title text NOT NULL,
    description text NOT NULL,
    start_time timestamp NOT NULL,
    end_time timestamp NOT NULL,
    capacity integer NOT NULL CHECK (capacity > 0),
    branch_id integer NOT NULL REFERENCES library_branch (branch_id),
    CHECK (end_time > start_time)
);

CREATE TABLE event_registration (
    registration_id integer PRIMARY KEY CHECK (registration_id > 0),
    registration_date date NOT NULL,
    attendance_status text NOT NULL,
    member_id integer NOT NULL REFERENCES member (member_id),
    event_id integer NOT NULL REFERENCES library_event (event_id),
    CONSTRAINT event_registration_member_event_key UNIQUE (member_id, event_id)
);

CREATE TABLE digital_resource (
    resource_id integer PRIMARY KEY CHECK (resource_id > 0),
    title text NOT NULL,
    resource_type text NOT NULL,
    url text NOT NULL,
    description text NOT NULL,
    organization_id integer NOT NULL REFERENCES organization (organization_id)
);

CREATE TABLE digital_license (
    license_id integer PRIMARY KEY CHECK (license_id > 0),
    start_date date NOT NULL,
    end_date date NOT NULL,
    concurrent_user_limit integer NOT NULL CHECK (concurrent_user_limit > 0),
    cost numeric(12, 2) NOT NULL CHECK (cost >= 0),
    resource_id integer NOT NULL REFERENCES digital_resource (resource_id),
    branch_id integer NOT NULL REFERENCES library_branch (branch_id),
    UNIQUE (license_id, resource_id),
    CHECK (end_date >= start_date)
);

CREATE TABLE digital_access_record (
    access_id integer PRIMARY KEY CHECK (access_id > 0),
    access_time timestamp NOT NULL,
    access_result text NOT NULL,
    member_id integer NOT NULL REFERENCES member (member_id),
    resource_id integer NOT NULL REFERENCES digital_resource (resource_id),
    license_id integer NOT NULL,
    FOREIGN KEY (license_id, resource_id) REFERENCES digital_license (license_id, resource_id)
);

-- Supplier offers and approval

CREATE TABLE offers (
    organization_id integer NOT NULL REFERENCES organization (organization_id),
    edition_id integer NOT NULL REFERENCES book_edition (edition_id),
    branch_id integer NOT NULL REFERENCES library_branch (branch_id),
    unit_price numeric(12, 2) NOT NULL CHECK (unit_price >= 0),
    lead_time_days integer NOT NULL CHECK (lead_time_days >= 0),
    PRIMARY KEY (organization_id, edition_id, branch_id)
);

CREATE TABLE approves (
    organization_id integer NOT NULL,
    edition_id integer NOT NULL,
    branch_id integer NOT NULL,
    librarian_id integer NOT NULL,
    approval_date date NOT NULL,
    PRIMARY KEY (organization_id, edition_id, branch_id),
    FOREIGN KEY (organization_id, edition_id, branch_id)
        REFERENCES offers (organization_id, edition_id, branch_id),
    FOREIGN KEY (librarian_id, branch_id) REFERENCES librarian (librarian_id, branch_id)
);

-- Course reserves and interlibrary loans

CREATE TABLE course (
    course_id integer PRIMARY KEY CHECK (course_id > 0),
    course_code text NOT NULL,
    title text NOT NULL,
    term text NOT NULL,
    department_id integer NOT NULL REFERENCES university_department (department_id)
);

CREATE TABLE course_reserve (
    reserve_id integer PRIMARY KEY CHECK (reserve_id > 0),
    start_date date NOT NULL,
    end_date date NOT NULL,
    max_loan_hours integer NOT NULL CHECK (max_loan_hours > 0),
    course_id integer NOT NULL REFERENCES course (course_id),
    item_id integer NOT NULL REFERENCES item (item_id),
    policy_id integer NOT NULL REFERENCES loan_policy (policy_id),
    CHECK (end_date >= start_date)
);

CREATE TABLE external_library (
    external_library_id integer PRIMARY KEY CHECK (external_library_id > 0),
    name text NOT NULL,
    address text NOT NULL,
    contact_email text NOT NULL
);

CREATE TABLE interlibrary_loan (
    ill_id integer PRIMARY KEY CHECK (ill_id > 0),
    direction text NOT NULL,
    request_date date NOT NULL,
    due_date date NOT NULL,
    return_date date,
    status text NOT NULL,
    member_id integer NOT NULL REFERENCES member (member_id),
    external_library_id integer NOT NULL REFERENCES external_library (external_library_id),
    branch_id integer NOT NULL REFERENCES library_branch (branch_id),
    item_id integer NOT NULL REFERENCES item (item_id),
    CHECK (due_date >= request_date),
    CHECK (return_date >= request_date)
);

-- Item is total and disjoint. The parent and its subtype may be inserted
-- in either order allowed by their foreign keys within one transaction.
-- Validation runs at commit, after both rows have been entered.
CREATE FUNCTION validate_item_subtype(target_id integer) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
    declared_type text;
    actual_count integer;
    matching_count integer;
BEGIN
    SELECT item_type INTO declared_type
    FROM item
    WHERE item_id = target_id
    FOR NO KEY UPDATE;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    SELECT count(*), count(*) FILTER (WHERE subtype = declared_type)
    INTO actual_count, matching_count
    FROM (
        SELECT 'Book' AS subtype FROM book WHERE item_id = target_id
        UNION ALL SELECT 'Periodical' FROM periodical WHERE item_id = target_id
        UNION ALL SELECT 'Thesis' FROM thesis WHERE item_id = target_id
        UNION ALL SELECT 'Media' FROM media WHERE item_id = target_id
    ) AS subtypes;

    IF actual_count <> 1 OR matching_count <> 1 THEN
        RAISE EXCEPTION 'Item % must have exactly one subtype matching %', target_id, declared_type
            USING ERRCODE = '23514';
    END IF;
END;
$$;

CREATE FUNCTION check_item_subtype() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP <> 'INSERT' THEN
        PERFORM validate_item_subtype(OLD.item_id);
    END IF;
    IF TG_OP = 'INSERT' THEN
        PERFORM validate_item_subtype(NEW.item_id);
    ELSIF TG_OP = 'UPDATE' AND NEW.item_id <> OLD.item_id THEN
        PERFORM validate_item_subtype(NEW.item_id);
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER item_subtype_check
AFTER INSERT OR UPDATE OR DELETE ON item
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_item_subtype();

CREATE CONSTRAINT TRIGGER book_subtype_check
AFTER INSERT OR UPDATE OR DELETE ON book
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_item_subtype();

CREATE CONSTRAINT TRIGGER periodical_subtype_check
AFTER INSERT OR UPDATE OR DELETE ON periodical
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_item_subtype();

CREATE CONSTRAINT TRIGGER thesis_subtype_check
AFTER INSERT OR UPDATE OR DELETE ON thesis
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_item_subtype();

CREATE CONSTRAINT TRIGGER media_subtype_check
AFTER INSERT OR UPDATE OR DELETE ON media
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_item_subtype();

-- Each physical copy or piece of equipment can have one open loan.
CREATE UNIQUE INDEX loan_one_open_copy
    ON loan (copy_id) WHERE copy_id IS NOT NULL AND return_date IS NULL;

CREATE UNIQUE INDEX loan_one_open_equipment
    ON loan (equipment_id) WHERE equipment_id IS NOT NULL AND return_date IS NULL;

-- A transfer without an arrival date is open unless it was cancelled.
CREATE UNIQUE INDEX copy_transfer_one_open_copy
    ON copy_transfer (copy_id)
    WHERE arrival_date IS NULL AND lower(btrim(status)) NOT IN ('cancelled', 'canceled');

-- Only a resolution status of Resolved closes a Lost report.
CREATE UNIQUE INDEX incident_report_one_unresolved_loss_per_copy
    ON incident_report (copy_id)
    WHERE report_type = 'Lost' AND lower(btrim(resolution_status)) <> 'resolved';

COMMIT;
