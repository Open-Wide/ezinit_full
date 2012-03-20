delimiter $$
create database {NAME} character set 'utf8' collate utf8_general_ci;
grant all on {NAME}.* to {NAME}@localhost identified by "{NAME}";
flush privileges;
$$
delimiter ;
