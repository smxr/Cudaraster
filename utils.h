#include <iostream>
#include <chrono>

using namespace std;

/*
 * 打印耗时，取变量构造函数与析构函数的时间差，单位ms
 */
class SpendTime
{
	public:
		SpendTime():_curTimePoint(std::chrono::steady_clock::now())
		{
		}

		~SpendTime(){
			auto curTime = std::chrono::steady_clock::now();
			auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(curTime - _curTimePoint);
			cout<<"SpendTime = "<<  duration.count() <<"ms"<<endl;
		}

	private:
		std::chrono::steady_clock::time_point _curTimePoint;
};
//SpendTime *time=new SpendTime();
//delete time;


class SpendTimemicroseconds
{
	public:
	SpendTimemicroseconds():_curTimePoint(std::chrono::steady_clock::now())
		{
		}

		~SpendTimemicroseconds(){
			auto curTime = std::chrono::steady_clock::now();
			auto duration = std::chrono::duration_cast<std::chrono::microseconds>(curTime - _curTimePoint);
			cout<<"SpendTime = "<<  duration.count() <<"microseconds"<<endl;
		}

	private:
		std::chrono::steady_clock::time_point _curTimePoint;
};
