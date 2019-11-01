//
#ifndef __MY_EVENT_H__
#define __MY_EVENT_H__

#include <string>

typedef std::string EventID;

class CMyEvent {
 public:
  template <class TParam = void, class TSource = MyObject, class TTarget = MyObject>
  CMyEvent(const EventID& name = "", TParam* param = 0,TSource source = 0,TTarget target = 0)
      : strName(name) {
    pParam = param;
    pSource = dynamic_cast<MyObject*>(source);
    pTarget = dynamic_cast<MyObject*>(target);
  }

  template <class TParam = void, class TSource = MyObject, class TTarget = MyObject>
  CMyEvent(const EventID& name = "", 
      std::shared_ptr<TParam> param = 0,
      std::shared_ptr<TSource> source = 0,
      std::shared_ptr<TTarget> target = 0)
      : strName(name) {
    pParam = param.get();
    pSource = std::dynamic_pointer_cast<MyObject>(source).get();
    pTarget = std::dynamic_pointer_cast<MyObject>(target).get();
  }

  virtual ~CMyEvent() {}

  void SetName(const EventID& name) { strName = name; }
  const EventID& GetName() { return strName; }

  template <class T>
  void SetParam(T* param) {
    pParam = param;
  }

  template <class T>
  T GetParam() {
    return (T*)pParam;
  }

  template <class T = MyObject>
  void SetSource(T source) {
    pSource = dynamic_cast<MyObject>(source);
  };

  template <class T = MyObject>
  T GetSource() {
    return dynamic_cast<T>(pSource);
  }

  template <class T>
  void SetTarget(T target) {
    pTarget = dynamic_cast<MyObject>(target);;
  }

  template <class T>
  T GetTarget() {
    return dynamic_cast<T>(pTarget);
  }

 protected:
  EventID strName;                    //事件名
  void* pParam;       //参数
  MyObject* pSource;  //源
  MyObject* pTarget;  //目标
};

#endif  //__CLIENT_EVENT_H__
