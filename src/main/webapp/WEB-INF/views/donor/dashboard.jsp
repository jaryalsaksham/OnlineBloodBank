<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<jsp:include page="/WEB-INF/views/common/header.jsp">
    <jsp:param name="title" value="My Dashboard"/>
    <jsp:param name="nav" value="donor"/>
</jsp:include>

<div class="container">
    <div class="page-head">
        <h1>Welcome, <c:out value="${me.fullName}"/></h1>
        <p class="muted">Thank you for being a blood donor.</p>
    </div>

    <div class="grid grid-4">
        <div class="card stat"><div class="num"><c:out value="${me.bloodGroup}"/></div><div class="lbl">Your blood group</div></div>
        <div class="card stat">
            <div class="num" style="font-size:1.4rem;padding:6px 0">
                <c:choose>
                    <c:when test="${me.eligible}"><span class="badge badge-eligible" style="font-size:1rem">Eligible</span></c:when>
                    <c:otherwise><span class="badge badge-wait" style="font-size:1rem">Not yet eligible</span></c:otherwise>
                </c:choose>
            </div>
            <div class="lbl">Donation status</div>
        </div>
        <div class="card stat">
            <div class="num" style="font-size:1.3rem;padding:8px 0">
                <c:choose>
                    <c:when test="${empty me.lastDonationDate}">Never</c:when>
                    <c:otherwise><fmt:formatDate value="${me.lastDonationDate}" pattern="dd MMM yyyy"/></c:otherwise>
                </c:choose>
            </div>
            <div class="lbl">Last donation</div>
        </div>
        <div class="card stat">
            <div class="num" style="font-size:1.3rem;padding:8px 0">
                <c:choose>
                    <c:when test="${empty me.nextEligibleDate}">Now</c:when>
                    <c:when test="${me.eligible}">Now</c:when>
                    <c:otherwise><fmt:formatDate value="${me.nextEligibleDate}" pattern="dd MMM yyyy"/></c:otherwise>
                </c:choose>
            </div>
            <div class="lbl">Can donate from</div>
        </div>
    </div>

    <section class="section">
        <div class="btn-row" style="margin-bottom:16px">
            <a class="btn btn-outline" href="${ctx}/donor/profile">Edit profile</a>
            <a class="btn btn-outline" href="${ctx}/request-blood">Request blood</a>
        </div>
        <h2>My donation history</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Date</th><th>Blood group</th><th>Units</th><th>Notes</th></tr></thead>
                <tbody>
                <c:forEach var="d" items="${donations}">
                    <tr>
                        <td><fmt:formatDate value="${d.donationDate}" pattern="dd MMM yyyy"/></td>
                        <td><span class="badge badge-group"><c:out value="${d.bloodGroup}"/></span></td>
                        <td><c:out value="${d.units}"/></td>
                        <td><c:out value="${d.notes}"/></td>
                    </tr>
                </c:forEach>
                <c:if test="${empty donations}">
                    <tr><td colspan="4" class="empty-row">No donations recorded yet. Visit the blood bank to make your first donation.</td></tr>
                </c:if>
                </tbody>
            </table>
        </div>
    </section>
</div>

<jsp:include page="/WEB-INF/views/common/footer.jsp"/>
