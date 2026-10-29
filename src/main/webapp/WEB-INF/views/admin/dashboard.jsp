<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<jsp:include page="/WEB-INF/views/common/header.jsp">
    <jsp:param name="title" value="Admin Dashboard"/>
    <jsp:param name="nav" value="admin"/>
</jsp:include>
<jsp:include page="/WEB-INF/views/common/adminnav.jsp"><jsp:param name="tab" value="dashboard"/></jsp:include>

<div class="container">
    <div class="page-head">
        <h1>Dashboard</h1>
        <p class="muted">Overview of donors, stock and requests.</p>
    </div>

    <div class="grid grid-4">
        <div class="card stat"><div class="num"><c:out value="${totalDonors}"/></div><div class="lbl">Active donors</div></div>
        <div class="card stat"><div class="num"><c:out value="${eligibleDonors}"/></div><div class="lbl">Donors eligible today</div></div>
        <div class="card stat"><div class="num"><c:out value="${totalUnits}"/></div><div class="lbl">Units in stock</div></div>
        <div class="card stat"><div class="num"><c:out value="${donationCount}"/></div><div class="lbl">Donations recorded</div></div>
    </div>

    <div class="grid grid-2" style="margin-top:24px">
        <div class="card">
            <h3>Blood stock</h3>
            <c:forEach var="s" items="${stock}">
                <div style="display:grid;grid-template-columns:48px 1fr 70px;gap:10px;align-items:center;margin-bottom:8px">
                    <strong class="badge badge-group" style="text-align:center"><c:out value="${s.bloodGroup}"/></strong>
                    <div class="bar" style="margin:0"><span class="${s.level}" style="width:${s.percent}%"></span></div>
                    <span><c:out value="${s.units}"/> u
                        <c:if test="${s.low}"><span class="badge badge-${s.level}"><c:out value="${s.level}"/></span></c:if></span>
                </div>
            </c:forEach>
            <a href="${ctx}/admin/stock" class="small">Manage stock &rarr;</a>
        </div>

        <div class="card">
            <h3>Requests by status</h3>
            <div class="grid" style="grid-template-columns:repeat(2,1fr)">
                <div><span class="badge badge-PENDING">PENDING</span><div class="num" style="font-size:1.6rem;font-weight:700"><c:out value="${requestCounts['PENDING']}"/></div></div>
                <div><span class="badge badge-APPROVED">APPROVED</span><div class="num" style="font-size:1.6rem;font-weight:700"><c:out value="${requestCounts['APPROVED']}"/></div></div>
                <div><span class="badge badge-FULFILLED">FULFILLED</span><div class="num" style="font-size:1.6rem;font-weight:700"><c:out value="${requestCounts['FULFILLED']}"/></div></div>
                <div><span class="badge badge-REJECTED">REJECTED</span><div class="num" style="font-size:1.6rem;font-weight:700"><c:out value="${requestCounts['REJECTED']}"/></div></div>
            </div>
            <p style="margin-top:12px"><a href="${ctx}/admin/requests" class="small">All requests &rarr;</a></p>
        </div>
    </div>

    <section class="section">
        <h2>Pending requests needing action</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>ID</th><th>Requester</th><th>Hospital</th><th>Blood</th><th>Urgency</th><th>Submitted</th></tr></thead>
                <tbody>
                <c:forEach var="r" items="${pending}">
                    <tr>
                        <td>#<c:out value="${r.id}"/></td>
                        <td><c:out value="${r.requesterName}"/><br><span class="muted small"><c:out value="${r.phone}"/></span></td>
                        <td><c:out value="${r.hospital}"/>, <c:out value="${r.city}"/></td>
                        <td><span class="badge badge-group"><c:out value="${r.bloodGroup}"/></span> &times; <c:out value="${r.unitsRequired}"/></td>
                        <td><span class="badge badge-${r.urgency}"><c:out value="${r.urgency}"/></span></td>
                        <td><fmt:formatDate value="${r.requestedOn}" pattern="dd MMM, HH:mm"/></td>
                    </tr>
                </c:forEach>
                <c:if test="${empty pending}">
                    <tr><td colspan="6" class="empty-row">No pending requests. All caught up!</td></tr>
                </c:if>
                </tbody>
            </table>
        </div>
    </section>
</div>

<jsp:include page="/WEB-INF/views/common/footer.jsp"/>
