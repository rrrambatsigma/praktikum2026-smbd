--1
select count(t.TransactionID) as jumlah_transaksi, g.Country
from transactions t
join gasstation g on g.GasStationID = t.GasStationID
group by g.Country
order by jumlah_transaksi desc

--2
select c.segment, sum(t.Amount) as amount
FROM customers c
JOIN transactions t ON t.CustomerID = c.CustomerID
GROUP BY c.segment
ORDER BY amount DESC


--3