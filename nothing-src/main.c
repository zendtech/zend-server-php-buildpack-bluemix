#define _POSIX_C_SOURCE 2

#include <stdio.h>
#include <signal.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <mysql/mysql.h>

#define MY_SLEEP_SECONDS 1
#define MAX_SLEEP_TIME 3

typedef struct Params_t {
    const char *mysql_hostname;
    unsigned int mysql_port;
    const char *mysql_username;
    const char *mysql_password;
    const char *mysql_dbname;
    int server_id;
    const char *web_api_key_name;
    const char *web_api_key;
} Params;

void term_handler(int sig);
void finish_with_error();
void print_mysql_error();
void usage(const char *program_name);

MYSQL mysql;
char *query;
Params params;

int main(int argc, const char *argv[])
{
    signal(SIGTERM, term_handler);
    
    const char *create_procedure =
        "CREATE PROCEDURE %s.kill_stale_procs (IN timeout INT, IN dbname VARCHAR(1024))\n"
        "BEGIN\n"
        "  DECLARE finished INTEGER DEFAULT 0;\n"
        "  DECLARE pid INTEGER;\n"
        "  DECLARE cur CURSOR FOR SELECT id FROM information_schema.processlist WHERE command='Sleep' AND time >= timeout AND db = dbname;\n"
        "  DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;\n"
        "  OPEN cur;\n"
        "  REPEAT\n"
        "    FETCH cur INTO pid;\n"
        "    IF NOT finished THEN\n"
        "      KILL pid;\n"
        "    END IF;\n"
        "  UNTIL finished END REPEAT;\n"
        "END";
    
    const char *create_schema = "CREATE SCHEMA IF NOT EXISTS %s;";
    const char *create_table = "CREATE TABLE IF NOT EXISTS %s.zend_cf_remove_servers(id INTEGER);";
    const char *select_remove_servers = "SELECT id FROM %s.zend_cf_remove_servers;";
    const char *call = "CALL %s.kill_stale_procs(%d,'%s');";
    const char *delete_server = "DELETE FROM %s.zend_cf_remove_servers WHERE id = %d;";
    
    if(argc != 9 && argc != 6) {
        usage(argv[0]);
        exit(1);
    }
    
    if((query = malloc(sizeof(char) * 1024)) == NULL) {
        exit(3);
    }
    
    params.mysql_hostname = argv[1];
    params.mysql_port = atoi(argv[2]);
    params.mysql_username = argv[3];
    params.mysql_password = argv[4];
    params.mysql_dbname = argv[5];
    params.server_id = (argc == 9 ? atoi(argv[6]) : -1);
    params.web_api_key_name = (argc == 9 ? argv[7] : NULL);
    params.web_api_key = (argc == 9 ? argv[8] : NULL);
    
    mysql_init(&mysql);
    my_bool recon = true;
    mysql_options(&mysql,MYSQL_OPT_RECONNECT,&recon);
    if(mysql_real_connect(&mysql,params.mysql_hostname,params.mysql_username,params.mysql_password,NULL,params.mysql_port,NULL,CLIENT_REMEMBER_OPTIONS) == NULL) {
        finish_with_error();
    }
    
    sprintf(query,create_schema,params.mysql_dbname);
    if(mysql_query(&mysql,query))
        print_mysql_error();
    sprintf(query,create_procedure,params.mysql_dbname);
    if(mysql_query(&mysql,query))
        print_mysql_error();
    sprintf(query,create_table,params.mysql_dbname);
    if(mysql_query(&mysql,query))
        print_mysql_error();

    MYSQL_RES *result;
    MYSQL_ROW row;
    int status;
    int server_id;
    while(true) {
        sprintf(query,call,params.mysql_dbname,MAX_SLEEP_TIME,params.mysql_dbname);
        if(mysql_query(&mysql,query)) {
            print_mysql_error();
        }
        if(params.web_api_key_name != NULL) {
            sprintf(query,select_remove_servers,params.mysql_dbname);
            if(mysql_query(&mysql,query)) {
                print_mysql_error();
            } else {
                result = mysql_store_result(&mysql);
                while((row = mysql_fetch_row(result))) {
                    server_id = atoi(row[0]);
                    sprintf(query,"/app/zend-server-6-php-5.4/bin/zs-manage cluster-remove-server %d -N %s -K %s -f",server_id,params.web_api_key_name,params.web_api_key);
                    fprintf(stderr,"%s\n",query);
                    if(system(query) == -1) {
                        fprintf(stderr,"FAILED\n");
                    }
                    sprintf(query,delete_server,params.mysql_dbname,server_id);
                    if(mysql_query(&mysql,query)) {
                        print_mysql_error();
                    }
                }
            }
        }
        waitpid(-1,&status,WNOHANG);
        sleep(MY_SLEEP_SECONDS);
    }
}

void finish_with_error()
{
    fprintf(stderr, "%s\n", mysql_error(&mysql));
    mysql_close(&mysql);
    exit(2);
}

void print_mysql_error()
{
    fprintf(stderr, "%s\n", mysql_error(&mysql));
}

void term_handler(int sig)
{
    signal(sig,SIG_IGN);
    if(params.server_id != -1) {
        sprintf(query,"INSERT INTO %s.zend_cf_remove_servers(id) VALUES(%d);",params.mysql_dbname,params.server_id);
        mysql_query(&mysql,query);
    }
    mysql_close(&mysql);
    free(query);
    exit(0);
}

void usage(const char *program_name)
{
    printf("Usage:\n");
    printf("%s <hostname> <port> <username> <password> <db-name> <server-id> <web-api-key-name> <web-api-key>\n",program_name);
}
