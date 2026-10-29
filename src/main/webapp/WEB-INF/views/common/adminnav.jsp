<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<div class="container">
    <div class="subnav">
        <a href="${ctx}/admin/dashboard" class="${param.tab == 'dashboard' ? 'active' : ''}">Dashboard</a>
        <a href="${ctx}/admin/requests" class="${param.tab == 'requests' ? 'active' : ''}">Blood Requests</a>
        <a href="${ctx}/admin/donations" class="${param.tab == 'donations' ? 'active' : ''}">Donations</a>
        <a href="${ctx}/admin/stock" class="${param.tab == 'stock' ? 'active' : ''}">Blood Stock</a>
        <a href="${ctx}/admin/donors" class="${param.tab == 'donors' ? 'active' : ''}">Donors</a>
    </div>
</div>
