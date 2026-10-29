<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<jsp:include page="/WEB-INF/views/common/header.jsp">
    <jsp:param name="title" value="Donations"/>
    <jsp:param name="nav" value="admin"/>
</jsp:include>
<jsp:include page="/WEB-INF/views/common/adminnav.jsp"><jsp:param name="tab" value="donations"/></jsp:include>

<div class="container">
    <div class="page-head">
        <h1>Donations</h1>
        <p class="muted">Recording a donation adds the units to stock and updates the donor's next eligible date.</p>
    </div>

    <div class="card">
        <h3>Record a new donation</h3>
        <form action="${ctx}/admin/donations" method="post">
            <input type="hidden" name="csrf" value="${sessionScope.csrf}">
            <div class="form-grid donation-grid">
                <div class="field">
                    <label for="donorId">Donor</label>
                    <select id="donorId" name="donorId" required>
                        <option value="">Select donor</option>
                        <c:forEach var="d" items="${donors}">
                            <option value="${d.id}"><c:out value="${d.fullName}"/> (<c:out value="${d.bloodGroup}"/>, <c:out value="${d.city}"/>)</option>
                        </c:forEach>
                    </select>
                </div>
                <div class="field">
                    <label for="units">Units</label>
                    <input type="number" id="units" name="units" min="1" max="5" value="1" required>
                </div>
                <div class="field">
                    <label for="donationDate">Date</label>
                    <input type="date" id="donationDate" name="donationDate" max="${today}" value="${today}" required>
                </div>
                <div class="field">
                    <label for="notes">Notes (optional)</label>
                    <input type="text" id="notes" name="notes" maxlength="255" placeholder="e.g. Blood donation camp">
                </div>
                <button type="submit" class="btn">Record</button>
            </div>
        </form>
    </div>

    <section class="section">
        <h2>Donation history</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>#</th><th>Date</th><th>Donor</th><th>Group</th><th>Units</th><th>Notes</th></tr></thead>
                <tbody>
                <c:forEach var="d" items="${donations}">
                    <tr>
                        <td><c:out value="${d.id}"/></td>
                        <td><fmt:formatDate value="${d.donationDate}" pattern="dd MMM yyyy"/></td>
                        <td><c:out value="${d.donorName}"/></td>
                        <td><span class="badge badge-group"><c:out value="${d.bloodGroup}"/></span></td>
                        <td><c:out value="${d.units}"/></td>
                        <td><c:out value="${d.notes}"/></td>
                    </tr>
                </c:forEach>
                <c:if test="${empty donations}">
                    <tr><td colspan="6" class="empty-row">No donations recorded yet.</td></tr>
                </c:if>
                </tbody>
            </table>
        </div>
    </section>
</div>

<jsp:include page="/WEB-INF/views/common/footer.jsp"/>
