class Connection : boost::noncopyable {
  public:
  Connection(std::string connection_string) :
    api_.establish_connection(handle_, connection_string);
  }
  ~Connection() {
    SQLRETURN return_code = api_.free_handle(SQL_HANDLE_DBC, hdbc_);
    api.
    if (hstatement_) {
      SQLFreeHandle(SQL_HANDLE_STMT, hstatement_);
    }

    hdbc_ = NULL;
  }

  std::string format() {
    return connect_string_;
  }

  private:
    api api_;
    ConnectionHandle handle_;
    std::string connection_string_;
};

typedef boost::shared_ptr<Connection> ConnectionPtr;
std::string get_string_info(SQLUSMALLINT info_type) const;
