#ifndef HANDLES_H_
#define HANDLES_H_

#include <boost/shared_ptr.hpp>
#include <boost/noncopyable.hpp>

class Handle : boost::noncopyable {
  public:

  void * handle() const {
    return handle_;
  }

  bool operator==(const Handle& other) const {
    return handle_ == other.handle_;
  }

  bool operator!=(const Handle& other) const {
    return handle_ != other.handle_;
  }

  virtual signed short int type() const = 0;

  private:
    void * handle_;
};

class ConnectionHandle : Handle {
  public:
    ConnectionHandle(const Handle& input_handle);
    signed short int type() const;
    ~ConnectionHandle();
};

class StatementHandle : Handle {
  public:
    StatementHandle(const Handle& input_handle);
    signed short int type() const;
    ~StatementHandle();
};

typedef boost::shared_ptr<ConnectionHandle> ConnectionHandlePtr;

#endif // HANDLES_H_
