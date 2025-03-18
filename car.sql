CREATE TABLE cars (
    id int primary key auto_increment,
    name varchar(255) not null,
    description text
);

CREATE TABLE cars_log (
    id int primary key auto_increment,
    car_id int not null,
    action varchar(255) not null
);

DELIMITER $$
CREATE TRIGGER cars_after_insert AFTER INSERT ON cars FOR EACH ROW
BEGIN
    INSERT INTO cars_log (car_id, action) VALUES (new.id, 'insert');
END$$
DELIMITER ;

