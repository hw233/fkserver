////
#ifndef __SINGLETON_H__
#define __SINGLETON_H__

#include <memory>

template <class T>
class Singleton {
 public:
  static T* instance() {
    if (_instance.get() == 0) {
      _instance = std::shared_ptr<T>(new T);
    }
    return _instance.get();
  };
  static void Destroy() {
    if (_instance.get() != 0) {
      _instance = std::shared_ptr<T>(0);
    }
  }
  static bool IsExist() { return _instance.get() != 0; }

 protected:
  Singleton(){};
  ~Singleton(){};

 private:  //禁止拷贝构造和赋值
  Singleton(const Singleton&){};
  Singleton& operator=(const Singleton&){};

 private:
  static std::shared_ptr<T> _instance;
};

#define SingletonInstance(A) \
  template <>                \
  std::shared_ptr<A> Singleton<A>::_instance(0);

#define FriendBaseSingleton(A)   \
  friend class std::shared_ptr<A>; \
  friend class Singleton<A>;

//用法如下
// class A : public Singleton<A>
//{
// protected:
//	A(){};
//	~A(){};
//	friend class Singleton<A>;
//	friend class std::shared_ptr<A>;
//};

//在cpp中用下面的代码定义静态变量，假设我们的派生类为 A
// SingletonInstance(A);

#endif  // __SINGLETON_H__
