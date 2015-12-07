declare @bd date
declare @ed date
set @bd = '01.08.2015'
set @ed = '31.08.2015'

--Выставленно стационар
select DEPT_NAME, ILL_HISTORY,ID_CASE, YEAR(DATE_END) data,DATE_END, sumib, kolIB,kolsly4,1 flag 
into #t_eis 
from 
(
select DEPT_NAME, ILL_HISTORY,ID_CASE,DATE_END, SUM(cost) sumib, COUNT(*) kolIB, SUM(kol) kolsly4  from(
select DEPT_NAME,ILL_HISTORY,t3.ID_CASE, t3.DATE_END, sum(service_cost) cost, COUNT(*) kol from OPENquery(EISS, 'select * from case_services_accounts ') t
left join 
(
select * from OPENquery(EISS, 'select * from CASE_SERVICES') 
) t1 on  t.ID_ACCOUNT=t1.ID_ACCOUNT
left join
(
select * from OPENquery(EISS, 'select * from CASES')
) t3 on t1.ID_CASE=t3.ID_CASE
left join 
(
select * from OPENquery(EISS, 'select * from VMU_MU_DEPTS')
) t2 on t1.ID_DEPT=t2.ID_DEPT
where account_date between @bd and @ed
group by DEPT_NAME,ILL_HISTORY,t3.ID_CASE,t3.DATE_END
) t
group by DEPT_NAME,ILL_HISTORY, ID_CASE,DATE_END
) t

--Отказы стационар
insert into #t_eis 
select DEPT_NAME, ILLH,ID_CASE, YEAR(data) data, data, cost, 1 kolib ,1 kolsly4,-1 flag  from
(
select DEPT_NAME, 
case when t2.DATE_END IS null then t22.DATE_END else t2.DATE_END end data,
case when t2.ID_CASE is null then t22.ID_CASE else t2.ID_CASE end ID_CASE,
case when t2.ILL_HISTORY IS NULL then t22.ILL_HISTORY else t2.ILL_HISTORY end ILLH,														/*
																																		В таблице с отказами заполнены не все значения ID_CASE и ID_SERVICE, 
																																		а по ним потом тянем ILL_HISTORY из разных таблиц, поэтому тут кейс, 
																																		чтобы убрать NULLы и заполничть все поля с ILL_HISTORY
																																		*/
SUMM_REFUSE cost
from OPENquery(EISS,'select * from REFUSES ') t																							/*ACT_DATE  это Дата рст в ЕИС, а ReFUSE_DATE это дата ПП. 
																																		ACT_MODE не ясно, что но если 0, то в ЕИСе отказа не видно, позжтому фильтр.
																																		Ключ - ID_REFUSE*/

left join
(
select * from OPENquery(EISS, 'select * from REFUSES_OBJ ')																				
)t1 on t.ID_REFUSE=t1.ID_REFUSE																											/*Отказы с ID_CASE и ID_SERVICE и суммой отказа. 
																																		Еще есть процент отказа. Не ясно учитывается он или нет в сумме отказа. UPD:
																																		Не учитывается, по крайней мере в друго отчете по отказам, берем просто сумму отказа без умножения на коэф.
																																		(Спросить у Якиной)
																																		*/
left join 
(
select ID_DEPT,ID_CASE,ILL_HISTORY, DATE_END from OPENquery(EISS, 'select * from CASES')												/*
																																		Услуги с номером истории болезни. Именно по ID_CASE тянем номер ИБ к отказу.
																																		*/
group by ID_DEPT, ID_CASE, ILL_HISTORY, DATE_END
) t2 on  t1.ID_CASE=t2.ID_CASE

																																		
left join 
(
select t1.ID_DEPT,t1.ID_CASE,ILL_HISTORY,ID_SERVICE,t1.DATE_END from OPENquery(EISS, 'select * from CASE_SERVICES') t
	left join 
	(
	select ID_DEPT,ID_CASE,ILL_HISTORY,DATE_END from OPENquery(EISS, 'select * from CASES') 
	)t1 on t.ID_CASE=t1.ID_CASE
) t22 on  t1.ID_SERVICE=t22.ID_SERVICE																									/*
																																		В таблице с отказами REFUSES_OBJ не у всех кортежей есть ID_CASE, но у них есть ID_SERVICE.
																																		Поэтому берем таблицу CASE_SERVICES, где есть соответствие между ID_SERVICE и ID_CASE(from CASES)
																																		и джойним к ней CASES из последней берем номер ИБ -> profit
																																		*/
left join 
(
select * from OPENquery(EISS, 'select * from VMU_MU_DEPTS')
) t3 on t2.ID_DEPT=t3.ID_DEPT or t22.ID_DEPT=t3.ID_DEPT																					/*
																																		Тут все понятно - название отделения.
																																		*/
where ACT_DATE between @bd and @ed and total_summ<>0 and ACT_MODE <>0 																																		
) t

--Выставленно поликлиника
insert into #t_eis select DEPT_NAME, ILL_HISTORY,ID_CASE, YEAR(DATE_END),DATE_END,sumib,kolIB,kolsly4,1 flag from 
(
select DEPT_NAME, ILL_HISTORY,ID_CASE, DATE_END, SUM(cost) sumib, COUNT(*) kolIB, SUM(kol) kolsly4  from(
select DEPT_NAME,ILL_HISTORY,t3.ID_CASE,t3.DATE_END, sum(service_cost) cost, COUNT(*) kol from OPENquery(EIS, 'select * from case_services_accounts ') t
left join 
(
select * from OPENquery(EIS, 'select * from CASE_SERVICES') 
) t1 on  t.ID_ACCOUNT=t1.ID_ACCOUNT
left join
(
select * from OPENquery(EIS, 'select * from CASES') 
) t3 on t1.ID_CASE=t3.ID_CASE
left join 
(
select * from OPENquery(EIS, 'select * from VMU_MU_DEPTS')
) t2 on t1.ID_DEPT=t2.ID_DEPT
where account_date between @bd and @ed
group by DEPT_NAME,ILL_HISTORY,t3.ID_CASE,t3.DATE_END
) t
group by DEPT_NAME, ILL_HISTORY, ID_CASE, DATE_END
) t

--Отказы поликлиника
insert into #t_eis select DEPT_NAME,ILLH,ID_CASE, YEAR(DATE_END), DATE_END,cost,1 kolib,1 kolsly4,-1 flag from
(
select DEPT_NAME,t2.DATE_END,
case when t2.ID_CASE is null then t22.ID_CASE else t2.ID_CASE end ID_CASE,
case when t2.ILL_HISTORY IS NULL then t22.ILL_HISTORY else t2.ILL_HISTORY end ILLH,														/*
																																		В таблице с отказами заполнены не все значения ID_CASE и ID_SERVICE, 
																																		а по ним потом тянем ILL_HISTORY из разных таблиц, поэтому тут кейс, 
																																		чтобы убрать NULLы и заполничть все поля с ILL_HISTORY
																																		*/
SUMM_REFUSE cost 
from OPENquery(EIS,'select * from REFUSES') t																							/*ACT_DATE  это Дата рст в ЕИС, а ReFUSE_DATE это дата ПП. 
																																		ACT_MODE не ясно, что но если 0, то в ЕИСе отказа не видно, позжтому фильтр.
																																		Ключ - ID_REFUSE*/

left join
(
select * from OPENquery(EIS, 'select * from REFUSES_OBJ ')																				
)t1 on t.ID_REFUSE=t1.ID_REFUSE																											/*Отказы с ID_CASE и ID_SERVICE и суммой отказа. 
																																		Еще есть процент отказа. Не ясно учитывается он или нет в сумме отказа. UPD:
																																		Не учитывается, по крайней мере в друго отчете по отказам, берем просто сумму отказа без умножения на коэф.
																																		(Спросить у Якиной)
																																		*/
left join 
(
select ID_DEPT,ID_CASE,ILL_HISTORY,DATE_END from OPENquery(EIS, 'select * from CASES')															/*
																																		Услуги с номером истории болезни. Именно по ID_CASE тянем номер ИБ к отказу.
																																		*/
group by ID_DEPT,ID_CASE,ILL_HISTORY,DATE_END
) t2 on  t1.ID_CASE=t2.ID_CASE

																																		
left join 
(
select t1.ID_DEPT,t1.ID_CASE,ILL_HISTORY,ID_SERVICE from OPENquery(EIS, 'select * from CASE_SERVICES') t
	left join 
	(
	select ID_DEPT,ID_CASE,ILL_HISTORY from OPENquery(EIS, 'select * from CASES') 
	)t1 on t.ID_CASE=t1.ID_CASE
) t22 on  t1.ID_SERVICE=t22.ID_SERVICE																									/*
																																		В таблице с отказами REFUSES_OBJ не у всех кортежей есть ID_CASE, но у них есть ID_SERVICE.
																																		Поэтому берем таблицу CASE_SERVICES, где есть соответствие между ID_SERVICE и ID_CASE(from CASES)
																																		и джойним к ней CASES из последней берем номер ИБ -> profit
																																		*/
left join 
(
select * from OPENquery(EIS, 'select * from VMU_MU_DEPTS')
) t3 on t2.ID_DEPT=t3.ID_DEPT or t22.ID_DEPT=t3.ID_DEPT																					/*
																																		Тут все понятно - название отделения.
																																		*/
where ACT_DATE between @bd and @ed and total_summ<>0 and ACT_MODE <>0 
) t


select * from #t_eis

order by DEPT_NAME,ILL_HIStory,flag
drop table #t_eis