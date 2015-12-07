select MSR_UsrCode,PLH_Price from
(
select MSR_UsrCode,MAX(PLH_Code) code from finance.dbo.medservice m 
			inner join finance.dbo.pricehistory p
				on MSR_Delete!=1 and PLH_Fixed = 1 and MSR_Code = PLH_MSR_Code 
					group by MSR_UsrCode
					) t
					left join finance.dbo.pricehistory p on t.code=p.PLH_Code
			