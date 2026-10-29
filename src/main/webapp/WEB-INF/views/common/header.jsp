<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" scope="request"/>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><c:out value="${empty param.title ? 'Home' : param.title}"/> | Online Blood Bank</title>
    <link rel="stylesheet" href="${ctx}/assets/css/style.css">
</head>
<body>
<header class="topbar">
    <div class="container nav">
        <a class="brand" href="${ctx}/home"><span class="drop">.</span> Online Blood Bank</a>
        <nav>
            <a href="${ctx}/home" class="${param.nav == 'home' ? 'active' : ''}">Home</a>
            <a href="${ctx}/search" class="${param.nav == 'search' ? 'active' : ''}">Find Donors</a>
            <a href="${ctx}/request-blood" class="${param.nav == 'request' ? 'active' : ''}">Request Blood</a>
            <a href="${ctx}/request-status" class="${param.nav == 'status' ? 'active' : ''}">Track Request</a>
            <c:choose>
                <c:when test="${not empty sessionScope.admin}">
                    <a href="${ctx}/admin/dashboard" class="${param.nav == 'admin' ? 'active' : ''}">Admin Panel</a>
                    <form action="${ctx}/logout" method="post">
                        <input type="hidden" name="csrf" value="${sessionScope.csrf}">
                        <button type="submit" class="linklike">Logout (<c:out value="${sessionScope.admin.username}"/>)</button>
                    </form>
                </c:when>
                <c:when test="${not empty sessionScope.donor}">
                    <a href="${ctx}/donor/dashboard" class="${param.nav == 'donor' ? 'active' : ''}">My Dashboard</a>
                    <form action="${ctx}/logout" method="post">
                        <input type="hidden" name="csrf" value="${sessionScope.csrf}">
                        <button type="submit" class="linklike">Logout</button>
                    </form>
                </c:when>
                <c:otherwise>
                    <a href="${ctx}/login" class="${param.nav == 'login' ? 'active' : ''}">Donor Login</a>
                    <a href="${ctx}/register" class="btn btn-sm">Become a Donor</a>
                    <a href="${ctx}/admin-login" class="${param.nav == 'adminlogin' ? 'active' : ''}">Admin</a>
                </c:otherwise>
            </c:choose>
        </nav>
    </div>
</header>

<c:if test="${not empty sessionScope.flash}">
    <div class="container">
        <div class="alert alert-${sessionScope.flashType}"><c:out value="${sessionScope.flash}"/></div>
    </div>
    <c:remove var="flash" scope="session"/>
    <c:remove var="flashType" scope="session"/>
</c:if>
<main>
